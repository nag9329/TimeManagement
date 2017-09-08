//
//  TMLocationSearchTableViewController.h
//  TimeManagement
//
//  Created by Nagarjuna Ramagiri on 8/21/17.
//  Copyright © 2017 Personal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TMMapViewController.h"

@interface TMLocationSearchTableViewController : UITableViewController<UISearchResultsUpdating,MKLocalSearchCompleterDelegate>

@property (strong, nonatomic) MKMapView *mapView;
@property (nonatomic,weak) id <HandleMapSearch> handleMapSearchDelegate;

@end
