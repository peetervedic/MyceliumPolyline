//
//  ViewController.m
//  Mycelium
//
//  Created by Jonathon Bolitho on 19/08/2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//

//
//  MBXViewController.m
//  MBXMapKit iOS Demo v030
//
//  Copyright (c) 2014 Mapbox. All rights reserved.
//

#import "ViewController.h"
#import "MBXMapKit.h"
#import <CoreLocation/CoreLocation.h>
#import "Polyline+TransformableAttributes.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (nonatomic) MBXRasterTileOverlay *rasterOverlay;
@property (nonatomic) UIActionSheet *actionSheet;


@property (nonatomic) BOOL viewHasFinishedLoading;
@property (nonatomic) BOOL currentlyViewingAnOfflineMap;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    [self.mapView setShowsUserLocation:YES];

    
    
    // Configure the amount of storage to use for NSURLCache's shared cache: You can also omit this and allow NSURLCache's
    // to use its default cache size. These sizes determines how much storage will be used for performance caching of HTTP
    // requests made by MBXOfflineMapDownloader and MBXRasterTileOverlay. Please note that these values apply only to the
    // HTTP cache, and persistent offline map data is stored using an entirely separate mechanism.
    //
    NSUInteger memoryCapacity = 4 * 1024 * 1024;
    NSUInteger diskCapacity = 40 * 1024 * 1024;
    NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:nil];
    //[urlCache removeAllCachedResponses];
    [NSURLCache setSharedURLCache:urlCache];
    
    
    // Let the shared offline map downloader know that we want to be notified of changes in its state. This will allow us to
    // update the download progress indicator and the begin/cancel/suspend/resume buttons
    //
    MBXOfflineMapDownloader *sharedDownloader = [MBXOfflineMapDownloader sharedOfflineMapDownloader];
    [sharedDownloader setDelegate:self];
    
    // Turn off distracting MKMapView features which aren't relevant to this demonstration
    _mapView.rotateEnabled = NO;
    _mapView.pitchEnabled = NO;
    
    // Let the mapView know that we want to use delegate callbacks to provide customized renderers for tile overlays and views
    // for annotations. In order to make use of MBXRasterTileOverlay and MBXPointAnnotation, it is essential for your app to set
    // this delegate and implement MKMapViewDelegate's mapView:rendererForOverlay: and mapView:(MKMapView *)mapView viewForAnnotation:
    // methods.
    //
    _mapView.delegate = self;
    
    // Show the network activity spinner in the status bar
    //
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    // Configure a raster tile overlay to use the initial sample map
    //
    _rasterOverlay = [[MBXRasterTileOverlay alloc] initWithMapID:@"jonobolitho.j834jdml"];
    
    // Let the raster tile overlay know that we want to be notified when it has asynchronously loaded the sample map's metadata
    // (so we can set the map's center and zoom) and the sample map's markers (so we can add them to the map).
    //
    _rasterOverlay.delegate = self;
    
    // Add the raster tile overlay to our mapView so that it will immediately start rendering tiles. At this point the MKMapView's
    // default center and zoom don't match the center and zoom of the sample map, but that's okay. Adding the layer now will prevent
    // a percieved visual glitch in the UI (an empty map), and we'll fix the center and zoom when tileOverlay:didLoadMetadata:withError:
    // gets called to notify us that the raster tile overlay has finished asynchronously loading its metadata.
    //
    [_mapView addOverlay:_rasterOverlay];
    
    // If there was a suspended offline map download, resume it...
    // Note how the call above to initialize the shared map downloader happens before its delegate can be set. So now, in order
    // to know whether there might be a suspended download which was restored from disk, we need to poll and invoke any
    // necessary handler functions on our own.
    //
    if(sharedDownloader.state == MBXOfflineMapDownloaderStateSuspended)
    {
        [self offlineMapDownloader:sharedDownloader stateChangedTo:MBXOfflineMapDownloaderStateSuspended];
        [self offlineMapDownloader:sharedDownloader totalFilesExpectedToWrite:sharedDownloader.totalFilesExpectedToWrite];
        [self offlineMapDownloader:sharedDownloader totalFilesWritten:sharedDownloader.totalFilesWritten totalFilesExpectedToWrite:sharedDownloader.totalFilesExpectedToWrite];
        [[MBXOfflineMapDownloader sharedOfflineMapDownloader] resume];
    }

    _locationsArray = [[NSMutableArray alloc] init];

}


#pragma mark - Things for switching between maps

- (UIActionSheet *)universalActionSheet
{
    // This is the list of options for selecting which map should be shown by the demo app
    //
    return [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"World baselayer, no Apple",@"World overlay, Apple satellite",@"World baselayer, Apple labels",@"Regional baselayer, no Apple",@"Regional overlay, Apple streets",@"Alpha overlay, Apple streets", @"Offline map downloader", @"Offline map viewer", @"Attribution",nil];
}


- (IBAction)iPadInfoButtonAction:(id)sender {
    // This responds to the info button from the iPad storyboard getting pressed
    //
    if(_actionSheet.visible) {
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
        _actionSheet = nil;
    } else {
        _actionSheet = [self universalActionSheet];
        [_actionSheet showFromRect:((UIButton *)sender).frame inView:self.view animated:YES];
    }
}


- (IBAction)iPhoneInfoButtonAction:(id)sender {
    // This responds to the info button from the iPhone storyboard getting pressed
    //
    if(_actionSheet.visible) {
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
        _actionSheet = nil;
    } else {
        _actionSheet = [self universalActionSheet];
        [_actionSheet showFromRect:((UIButton *)sender).frame inView:self.view animated:NO];
    }
}


- (void)resetMapViewAndRasterOverlayDefaults
{
    // Reset the MKMapView to some reasonable defaults.
    //
    _mapView.mapType = MKMapTypeStandard;
    _mapView.scrollEnabled = YES;
    _mapView.zoomEnabled = YES;
    
    // Make sure that any downloads (tiles, metadata, marker icons) which might be in progress for
    // the old tile overlay are stopped, and remove the overlay and its markers from the MKMapView.
    // The invalidation step is necessary to avoid the possibility of visual glitching or crashes due to
    // delegate callbacks or asynchronous completion handlers getting invoked for downloads which might
    // be still in progress.
    //
    [_mapView removeAnnotations:_rasterOverlay.markers];
    [_mapView removeOverlay:_rasterOverlay];
    [_rasterOverlay invalidateAndCancel];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    _currentlyViewingAnOfflineMap = NO;
}





#pragma mark - AlertView stuff

- (void)areYouSureYouWantToDeleteAllOfflineMaps
{
    NSString *title = @"Are you sure you want to remove your offline maps?";
    NSString *message = @"This will permently delete your offline map data. This action cannot be undone.";
    UIAlertView *areYouSure = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"No", @"Yes", nil];
    [areYouSure show];
}

- (void)areYouSureYouWantToCancel
{
    NSString *title = @"Are you sure you want to cancel?";
    NSString *message = @"Canceling an offline map download permanently deletes its partially downloaded map data. This action cannot be undone.";
    UIAlertView *areYouSure = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"No", @"Yes", nil];
    [areYouSure show];
}

- (void)attribution:(NSString *)attribution
{
    NSString *title = @"Attribution";
    NSString *message = attribution;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Mapbox Details", @"OSM Details", nil];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if([alertView.title isEqualToString:@"Are you sure you want to cancel?"])
    {
        // For the are you sure you want to cancel alert dialog, do the cancel action if the answer was "Yes"
        //
        if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"])
        {
            [[MBXOfflineMapDownloader sharedOfflineMapDownloader] cancel];
        }
    }
    else if([alertView.title isEqualToString:@"Are you sure you want to remove your offline maps?"])
    {
        // For are you sure you want to remove offline maps alert dialog, do the remove action if the answer was "Yes"
        //
        if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"])
        {
            if(_currentlyViewingAnOfflineMap)
            {
                [self resetMapViewAndRasterOverlayDefaults];
                _rasterOverlay = [[MBXRasterTileOverlay alloc] initWithOfflineMapDatabase:nil];
                _rasterOverlay.delegate = self;
                [_mapView addOverlay:_rasterOverlay];
            }
            for(MBXOfflineMapDatabase *db in [MBXOfflineMapDownloader sharedOfflineMapDownloader].offlineMapDatabases)
            {
                [[MBXOfflineMapDownloader sharedOfflineMapDownloader] removeOfflineMapDatabase:db];
            }
            
        }
    }
    else if([alertView.title isEqualToString:@"Attribution"])
    {
        // For the attribution alert dialog, open the Mapbox and OSM copyright pages when their respective buttons are pressed
        //
        if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Mapbox Details"])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.mapbox.com/tos/"]];
        }
        if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OSM Details"])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.openstreetmap.org/copyright"]];
        }
    }
}




#pragma mark - Offline map download controls

- (IBAction)offlineMapButtonActionHelp:(id)sender
{
    NSString *title = @"Offline Map Downloader Help";
    NSString *message = @"Arrange the map to show the region you want to download for offline use, then press [Begin]. [Suspend] stops the downloading in such a way that you can [Resume] it later. [Cancel] stops the download and discards the partially downloaded files.";
    UIAlertView *help = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [help show];
}


- (IBAction)offlineMapButtonActionBegin:(id)sender
{
    [[MBXOfflineMapDownloader sharedOfflineMapDownloader] beginDownloadingMapID:_rasterOverlay.mapID mapRegion:_mapView.region minimumZ:_rasterOverlay.minimumZ maximumZ:MIN(16,_rasterOverlay.maximumZ)];
}


- (IBAction)offlineMapButtonActionCancel:(id)sender
{
    [self areYouSureYouWantToCancel];
}

- (IBAction)offlineMapButtonActionSuspendResume:(id)sender {
    if ([[MBXOfflineMapDownloader sharedOfflineMapDownloader] state] == MBXOfflineMapDownloaderStateSuspended)
    {
        [[MBXOfflineMapDownloader sharedOfflineMapDownloader] resume];
    }
    else
    {
        [[MBXOfflineMapDownloader sharedOfflineMapDownloader] suspend];
    }
}






#pragma mark - MKMapViewDelegate protocol implementation

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    // This is boilerplate code to connect tile overlay layers with suitable renderers
    //
    if ([overlay isKindOfClass:[MBXRasterTileOverlay class]])
    {
        MKTileOverlayRenderer *renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
        return renderer;
    }
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        
        renderer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
        renderer.lineWidth   = 3;
        
        return renderer;
    }
    
    return nil;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // This is boilerplate code to connect annotations with suitable views
    //
    if ([annotation isKindOfClass:[MBXPointAnnotation class]])
    {
        static NSString *MBXSimpleStyleReuseIdentifier = @"MBXSimpleStyleReuseIdentifier";
        MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:MBXSimpleStyleReuseIdentifier];
        if (!view)
        {
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MBXSimpleStyleReuseIdentifier];
        }
        view.image = ((MBXPointAnnotation *)annotation).image;
        view.canShowCallout = YES;
        return view;
    }
    return nil;
}


#pragma mark - MBXRasterTileOverlayDelegate implementation

- (void)tileOverlay:(MBXRasterTileOverlay *)overlay didLoadMetadata:(NSDictionary *)metadata withError:(NSError *)error
{
    // This delegate callback is for centering the map once the map metadata has been loaded
    //
    if (error)
    {
        NSLog(@"Failed to load metadata for map ID %@ - (%@)", overlay.mapID, error?error:@"");
    }
    else
    {
        [_mapView mbx_setCenterCoordinate:overlay.center zoomLevel:overlay.centerZoom animated:YES];
    }
}


- (void)tileOverlay:(MBXRasterTileOverlay *)overlay didLoadMarkers:(NSArray *)markers withError:(NSError *)error
{
    // This delegate callback is for adding map markers to an MKMapView once all the markers for the tile overlay have loaded
    //
    if (error)
    {
        NSLog(@"Failed to load markers for map ID %@ - (%@)", overlay.mapID, error?error:@"");
    }
    else
    {
        [_mapView addAnnotations:markers];
    }
}

- (void)tileOverlayDidFinishLoadingMetadataAndMarkers:(MBXRasterTileOverlay *)overlay
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}



- (void)viewWillAppear:(BOOL)animated {
    // if you do this, _locationsArray gets allocated every time you switch back to this screen. only do allocs in viewDidLoad
//    _locationsArray = [[NSMutableArray alloc] init];
}


#pragma mark Start Button

- (IBAction)startTracking:(id)sender{
    
    [UIView animateWithDuration:0.5 animations:^{
        _startTracking.alpha = 0;
    }];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
    locationManager.distanceFilter = 2;
    
}


#pragma mark CLLocation Manager


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    //get the latest location
    CLLocation *currentLocation = [locations lastObject];
    
   
    //get latest location coordinates
    CLLocationDegrees latitude = currentLocation.coordinate.latitude;
    CLLocationDegrees longitude = currentLocation.coordinate.longitude;
    CLLocationCoordinate2D locationCoordinates = CLLocationCoordinate2DMake(latitude, longitude);
    
    //zoom map to show users location
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(locationCoordinates, 2000, 2000);
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];
    
   
        //store latest location in stored track array
        [_locationsArray addObject:currentLocation];
   
    //create cllocationcoordinates to use for construction of polyline
    NSInteger numberOfSteps = _locationsArray.count;
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger index = 0; index < numberOfSteps; index++) {
        CLLocation *location = [_locationsArray objectAtIndex:index];
        CLLocationCoordinate2D coordinate2 = location.coordinate;
        coordinates[index] = coordinate2;
    }
    
    MKPolyline *routeLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    [_mapView addOverlay:routeLine];
    
    NSLog(@"%@", _locationsArray);
    
}


-(IBAction)didClickSaveCoordinates:(id)sender {
    
    
    // get a reference to the appDelegate so you can access the global managedObjectContext
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    // creates a new polyline object when app goes into the background, and stores it into core data.
    if (!polyLine) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Route" inManagedObjectContext:appDelegate.managedObjectContext];
        polyLine = (Route *)object;
    }
    
    [polyLine setCoordinates:_locationsArray];
    [polyLine setCreated_at:[NSDate date]];
    NSError *error;
    if ([appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Saved");
    }
    else {
        NSLog(@"Error: %@", error);
    }

    // clear locationsArray since you've already saved the current coordinates into core data. essentially this starts a new, disconnected route
    [_locationsArray removeAllObjects];
}



-(IBAction)didClickLoadCoordinates:(id)sender {
    // get a reference to the appDelegate so you can access the global managedObjectContext
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Route"];
    NSError *error;
    id results = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];

    // add a sort descriptor so you can sort by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created_at" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];

    for (Route * route in results) {
        // loop through all Routes saved into core data

        NSArray *coordinates = route.coordinates;
        int ct = 0;
        NSInteger numberOfSteps = coordinates.count;
        CLLocationCoordinate2D clCoordinates[numberOfSteps];

        // convert CLLocation array into a CLLocationCoordinate2D[]
        // you were doing two loops, so you were looping through each set of coordinates each time you looped through the whole array of coordinates. doing x^2 the work!
        for (CLLocation *loc in coordinates) {
            NSLog(@"location %d: %@", ct++, loc);
            CLLocationCoordinate2D coordinate2 = loc.coordinate;
            //convert to coordinates array to construct the polyline
            clCoordinates[ct] = coordinate2;
        }

        // create a new map overlay for each of the routes loaded from core data. these will be disconnected from each other.
        MKPolyline *routeLine = [MKPolyline polylineWithCoordinates:clCoordinates count:numberOfSteps];
        [_mapView addOverlay:routeLine];
    }

    // start with a fresh _locationsArray
    [_locationsArray removeAllObjects];
}

@end
