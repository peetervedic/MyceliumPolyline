//
//  ViewController.h
//  Mycelium
//
//  Created by Jonathon Bolitho on 19/08/2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//


@import MapKit;
#import "MBXMapKit.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Route+TransformableAttributes.h"



@interface ViewController : UIViewController <UIActionSheetDelegate, MKMapViewDelegate,MBXRasterTileOverlayDelegate, MBXOfflineMapDownloaderDelegate, UIAlertViewDelegate,CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    NSMutableArray *_locationsArray;
    Route *polyLine;

    BOOL isMapReady;
    BOOL startedTracking;
}

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIButton *startTracking;

-(IBAction)didClickSaveCoordinates:(id)sender;
-(IBAction)didClickLoadCoordinates:(id)sender;


@end
