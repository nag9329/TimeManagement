//
//  TMMapViewController.h
//  TimeManagement
//
//  Created by Nagarjuna Ramagiri on 8/21/17.
//  Copyright © 2017 Personal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol HandleMapSearch <NSObject>

- (void)dropPinZoomIn:(MKPlacemark *) placemark;

@end

@interface TMMapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate, HandleMapSearch>

@property (nonatomic, strong) MKPlacemark *selectedPin;

@end
