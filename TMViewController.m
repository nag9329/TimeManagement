//
//  ViewController.m
//  TimeManagement
//
//  Created by Nagarjuna Ramagiri on 8/21/17.
//  Copyright © 2017 Personal. All rights reserved.
//

#import "TMViewController.h"
#import "TMAppDelegate.h"
#import "Location+CoreDataProperties.h"

@interface TMViewController ()

@property (nonatomic, strong) NSArray<Location *> *locationsArray;
@property (weak, nonatomic) IBOutlet UITableView *locationsTableView;

@end

@implementation TMViewController


#pragma mark - View Controller life cycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.locationsTableView setTableFooterView:[[UIView alloc] init]];
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil]];
    [self.locationsTableView setRowHeight:UITableViewAutomaticDimension];
}

- (void)viewWillAppear:(BOOL)animated
{
     self.locationsArray = [NSArray arrayWithArray:[self locations]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Database Operations

- (NSArray *)locations
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    NSManagedObjectContext *moc = [[APP_DELEGATE persistentContainer] viewContext]; //Retrieve the main queue NSManagedObjectContext
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    if (!results) {
        NSLog(@"Error fetching Location objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return results;
}

#pragma mark - UITableView Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.locationsArray.count > 0)
    {
        self.locationsTableView.backgroundView = nil;
    }
    else
    {
        UILabel *noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.locationsTableView.bounds.size.width, self.locationsTableView.bounds.size.height)];
        noDataLabel.text = @"No locations are added yet to the app";
        noDataLabel.textAlignment    = NSTextAlignmentCenter;
        self.locationsTableView.backgroundView = noDataLabel;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.locationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TMLocationsTableViewCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TMLocationsTableViewCell"];
    }
    
    Location *location = [self.locationsArray objectAtIndex:indexPath.row];
    [cell.textLabel setNumberOfLines:0];
    [cell.textLabel setText:location.locationName];
    [cell.detailTextLabel setText:location.locationSubtitle];
    
    return cell;
}

#pragma mark - UITableView Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

@end
