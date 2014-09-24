//
//  Route.h
//  Mycelium
//
//  Created by Bobby Ren on 9/24/14.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Route : NSManagedObject

@property (nonatomic, retain) id coordinates;
@property (nonatomic, retain) NSData * coordinates_data;
@property (nonatomic, retain) UNKNOWN_TYPE created_at;

@end
