//
//  ViewController.h
//  Mycelium
//
//  Created by Jonathon Bolitho on 19/08/2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//


@import MapKit;
@import UIKit;


#import "MBXMapKit.h"
#import <CoreLocation/CoreLocation.h>

@interface MBXViewController : UIViewController <UIActionSheetDelegate, MKMapViewDelegate, MBXRasterTileOverlayDelegate, MBXOfflineMapDownloaderDelegate, UIAlertViewDelegate>
    



 
- (IBAction)startTracking:(id)sender;
@property NSMutableArray *locationsArray;
@property CLLocationManager *manager;




@end
