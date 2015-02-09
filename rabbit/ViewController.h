//
//  ViewController.h
//  rabbit
//
//  Created by Brian Batchelder on 2/4/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <PTDBeanManager.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate, PTDBeanManagerDelegate, PTDBeanDelegate>

@property (weak, nonatomic) IBOutlet UITextField *pace;

@end

