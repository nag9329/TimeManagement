//
//  TMLocationSearchTableViewController.m
//  TimeManagement
//
//  Created by Nagarjuna Ramagiri on 8/21/17.
//  Copyright © 2017 Personal. All rights reserved.
//

#import "TMLocationSearchTableViewController.h"

@interface TMLocationSearchTableViewController ()

@property (nonatomic, strong) MKLocalSearchCompleter *request;
@property (strong, nonatomic) MKLocalSearchCompleter *completer;

@end

@implementation TMLocationSearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.request = [[MKLocalSearchCompleter alloc] init];
    [self.request setDelegate:self];
    [self.request setRegion:self.mapView.region];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.completer.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    MKLocalSearchCompletion *localSearchCompletion = self.completer.results[indexPath.row];
    
    [cell.textLabel setText:localSearchCompletion.title];
    [cell.detailTextLabel setText:localSearchCompletion.subtitle];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MKLocalSearchCompletion *localSearchCompletion = self.completer.results[indexPath.row];
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] initWithCompletion:localSearchCompletion];
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        [self.handleMapSearchDelegate dropPinZoomIn:response.mapItems[0].placemark];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
   
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

#pragma mark - UISearchController delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self.request setQueryFragment:searchController.searchBar.text];
}

#pragma mark - MKLocalSearch delegate

- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer
{
    [self setCompleter:completer];
    [self.tableView reloadData];
}

@end
