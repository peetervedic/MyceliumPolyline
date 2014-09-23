//
//  Polyline.h
//  Mycelium
//
//  Created by Jonathon Bolitho on 4/09/2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Route : NSManagedObject

@property (nonatomic, retain) id coordinates;
@property (nonatomic, retain) NSData * coordinates_data;

@end
