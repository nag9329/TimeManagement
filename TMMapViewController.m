//
//  TMMapViewController.m
//  TimeManagement
//
//  Created by Nagarjuna Ramagiri on 8/21/17.
//  Copyright © 2017 Personal. All rights reserved.
//

#import "TMMapViewController.h"
#import "TMAppDelegate.h"
#import "TMLocationSearchTableViewController.h"
#import "Reachability/Reachability.h"
#import "Location+CoreDataProperties.h"

@interface TMMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UISearchController *resultSearchController;

@end

@implementation TMMapViewController

#pragma mark - View Controller Life Cycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self checkInternetPresence];
    
    // Initialize Location Manager
    self.locationManager = [[CLLocationManager alloc] init];
    
    // Configure Location Manager
    [self.locationManager setDelegate:self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager requestLocation];
    
    TMLocationSearchTableViewController *locationSearchTable = (TMLocationSearchTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LocationSearchTable"];
    self.resultSearchController =  [[UISearchController alloc] initWithSearchResultsController:locationSearchTable];
    [self.resultSearchController setSearchResultsUpdater:locationSearchTable];
    [locationSearchTable setMapView:self.mapView];
    [locationSearchTable setHandleMapSearchDelegate:self];
    
    UISearchBar *searchBar = self.resultSearchController.searchBar;
    [searchBar sizeToFit];
    [searchBar setPlaceholder:@"Search for places"];
    [self.navigationItem setTitleView:self.resultSearchController.searchBar];
    
    [self.resultSearchController setHidesNavigationBarDuringPresentation:NO];
    [self.resultSearchController setDimsBackgroundDuringPresentation:YES];
    [self setDefinesPresentationContext:YES];
    
    [self.mapView setDelegate:self];
}

#pragma mark - CLLocationManager Delegate methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status == kCLAuthorizationStatusAuthorizedAlways)
    {
        [self.locationManager requestLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = locations[0].coordinate;
    mapRegion.span = MKCoordinateSpanMake(0.01, 0.01);
    [self.mapView setRegion:mapRegion animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"error:: %@",error);
}

#pragma mark - Mapview delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    NSString *reuseId = @"pin";
    MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
    [pinView setPinTintColor:[UIColor orangeColor]];
    [pinView setCanShowCallout:YES];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [button setBackgroundImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addLocation) forControlEvents:UIControlEventTouchUpInside];
    [pinView setLeftCalloutAccessoryView:button];
    return pinView;
}

#pragma HandleMapSearch delegate

- (void)dropPinZoomIn:(MKPlacemark *)placemark
{
    self.selectedPin = placemark;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:placemark.coordinate];
    [annotation setTitle: placemark.title];
    if (placemark.locality && placemark.administrativeArea) {
        [annotation setSubtitle:[NSString stringWithFormat:@"(%@) (%@)", placemark.locality, placemark.administrativeArea]];
    }
    
    [self.mapView addAnnotation:annotation];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
    MKCoordinateRegion region = MKCoordinateRegionMake(placemark.coordinate, span);
    [self.mapView setRegion:region];
}

#pragma mark - Helper methods

- (void)appDidBecomeActive:(NSNotification *)notification
{
    [self checkInternetPresence];
}

- (void)checkInternetPresence
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cellular Data is Turned Off" message:@"Turn on cellular Data or use Wi-Fi to access data." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"prefs:root=Cellular"]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Cellular"] options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Cellular"] options:@{} completionHandler:nil];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)addLocation
{
    for (MKPointAnnotation *annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
            if (![self checkIfAnnotaionIsPresentLocally:annotation]) { //location is not present in the core data
                CLLocation *location = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
                NSString *uniqueIdentifier = [[NSUUID UUID] UUIDString];
                CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:[location coordinate] radius:160.0 identifier:uniqueIdentifier]; //radius 160.0 hardcoded for now.
                [self.locationManager startMonitoringForRegion:region];
                [self insertIntoDatabaseWithLocation:annotation uniqueIdentifier:uniqueIdentifier];
            }
        }
    }
}

#pragma mark - Database Operations

- (BOOL)checkIfAnnotaionIsPresentLocally: (MKPointAnnotation *)annotation
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(latitude = %f) AND (longitude = %f)", annotation.coordinate.latitude, annotation.coordinate.longitude];
    [request setPredicate: predicate];
    NSManagedObjectContext *moc = [[APP_DELEGATE persistentContainer] viewContext]; //Retrieve the main queue NSManagedObjectContext
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    if (!results) {
        NSLog(@"Error fetching Employee objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    if (results.count > 0) {
        return YES;
    }
    return NO;
}

- (void)insertIntoDatabaseWithLocation:(MKPointAnnotation *)annotation uniqueIdentifier:(NSString *)uniqueIdentifier
{

    Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:[[APP_DELEGATE persistentContainer] viewContext]];
    
    //setting all the properties of the location table
    [location setLatitude:annotation.coordinate.latitude];
    [location setLongitude:annotation.coordinate.longitude];
    [location setLocationName:annotation.title];
    [location setLocationSubtitle:annotation.subtitle];
    [location setLocationUUID:uniqueIdentifier];
    
    //save to the database
    [APP_DELEGATE saveContext];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location Added successfully" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
