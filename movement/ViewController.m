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
@end

@implementation ViewController

@synthesize locationManager = _locationManager;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _pace.text = @"7:00";
    [self startStandardUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
