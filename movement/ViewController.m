//
//  ViewController.m
//  movement
//
//  Created by Brian Batchelder on 2/4/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *previousLocations;
@property (nonatomic, strong) PTDBeanManager *beanManager;
// all the beans returned from a scan
@property (nonatomic, strong) NSMutableDictionary *beans;
@property (nonatomic, strong) PTDBean *bean;
@property (nonatomic, strong) CLLocation *firstLocation;
@end

@implementation ViewController

@synthesize locationManager = _locationManager;
@synthesize previousLocations = _previousLocations;

- (void)startStandardUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    
    [_locationManager requestAlwaysAuthorization];
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    //_locationManager.distanceFilter = 500; // meters
    
    [_locationManager startUpdatingLocation];
}

#define METERS_PER_MILE 1609.34
#define MINUTES_PER_HOUR 60
#define SECONDS_PER_MINUTE 60
#define SECONDS_PER_HOUR (MINUTES_PER_HOUR * SECONDS_PER_MINUTE)
#define TIME_DELTA_FOR_LEVELING_IN_SECONDS 20

// Delegate method from the CL_locationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* location = [locations lastObject];
    
    if (!_firstLocation) {
        _firstLocation = location;
    }
    
    NSTimeInterval timeIntervalSinceFirstLocationUpdate = [location.timestamp timeIntervalSinceFirstLocationUpdateSinceDate:_firstLocation.timestamp];
    if (timeIntervalSinceFirstLocationUpdate < 10) {
        [self off];
    } else if (timeIntervalSinceFirstLocationUpdate > 10 && timeIntervalSinceFirstLocationUpdate < 20) {
        [self speedUp];
    } else if (timeIntervalSinceFirstLocationUpdate > 20 && timeIntervalSinceFirstLocationUpdate < 30) {
        [self justRight];
    } else if (timeIntervalSinceFirstLocationUpdate > 30 && timeIntervalSinceFirstLocationUpdate < 40) {
        [self slowDown];
    } else if (timeIntervalSinceFirstLocationUpdate > 40 && timeIntervalSinceFirstLocationUpdate < 50) {
        [self justRight];
    }
    
    NSLog(@"");
    if ([_previousLocations count] == 0) {
        [_previousLocations addObject:location];
    } else {
        BOOL cleanedLocations = NO;
        CLLocation *_oldestLocation = nil;
        while (!cleanedLocations) {
            _oldestLocation = [_previousLocations objectAtIndex:0];
            NSTimeInterval timeDeltaInSeconds = [location.timestamp timeIntervalSinceDate:_oldestLocation.timestamp];
            if (timeDeltaInSeconds > TIME_DELTA_FOR_LEVELING_IN_SECONDS) {
                [_previousLocations removeObjectAtIndex:0];
            } else {
                cleanedLocations = YES;
            }
        }
        [_previousLocations addObject:location];
        
        NSTimeInterval timeDeltaInSeconds = [location.timestamp timeIntervalSinceDate:_oldestLocation.timestamp];
        
        CLLocation *lastLocation = nil;
        double distanceInMeters = 0;
        for (CLLocation *thisLocation in _previousLocations) {
            if (lastLocation) {
                distanceInMeters += [thisLocation distanceFromLocation:lastLocation];
            }
            lastLocation = thisLocation;
        }
        
        NSLog(@"distance (meters) = %f",distanceInMeters);
        if (distanceInMeters > 0) {
            
            NSLog(@"time delta (seconds) = %f",timeDeltaInSeconds);
            double speedInMetersPerSecond = distanceInMeters / timeDeltaInSeconds;
            NSLog(@"speed %+.6f meters/second\n", speedInMetersPerSecond);
            if (speedInMetersPerSecond <= 0) {
                _pace.text = @"Not moving";
            } else {
                double milesPerHour = (speedInMetersPerSecond/METERS_PER_MILE*SECONDS_PER_HOUR);
                NSLog(@"speed %+.6f miles/hour\n", milesPerHour);
                double minutesPerMile = MINUTES_PER_HOUR / milesPerHour;
                NSLog(@"pace %+.6f minutes/miles\n", minutesPerMile);
                
                double minutes;
                double fractPart = modf(minutesPerMile,&minutes);
                double seconds = fractPart*SECONDS_PER_MINUTE;
                _pace.text = [NSString stringWithFormat:@"%2.0f:%02.0f",minutes,seconds];
            }
        } else {
            _pace.text = @"Not moving";
        }
    }
}

- (void)slowDown {
    NSString *serialString = [NSString stringWithFormat:@"%d\n",0];
    NSLog(@"serialString = %@",serialString);
    [self.bean sendSerialString:serialString];
}

- (void)justRight {
    NSString *serialString = [NSString stringWithFormat:@"%d\n",1];
    NSLog(@"serialString = %@",serialString);
    [self.bean sendSerialString:serialString];
}

- (void)speedUp {
    NSString *serialString = [NSString stringWithFormat:@"%d\n",2];
    NSLog(@"serialString = %@",serialString);
    [self.bean sendSerialString:serialString];
}

- (void)off {
    NSString *serialString = [NSString stringWithFormat:@"%d\n",3];
    NSLog(@"serialString = %@",serialString);
    [self.bean sendSerialString:serialString];
}


- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        [self.beanManager startScanningForBeans_error:nil];
    }
    else if (self.beanManager.state == BeanManagerState_PoweredOff) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Turn on bluetooth to continue" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    self.bean = bean;
    NSUUID * key = bean.identifier;
    if (![self.beans objectForKey:key]) {
        // New bean
        NSLog(@"BeanManager:didDiscoverBean:error %@", bean);
        [self.beans setObject:bean forKey:key];
        
        if (bean.state == BeanState_Discovered) {
            bean.delegate = self;
            [self.beanManager connectToBean:bean error:nil];
        }

    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    [self off];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _pace.text = @"7:00";
    _previousLocations = [[NSMutableArray alloc] init];
    
    self.beans = [NSMutableDictionary dictionary];
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    
    [self startStandardUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.beanManager.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
