//
//  Polyline+TransformableAttributes.h
//  Mycelium
//
//  Created by Jonathon Bolitho on 4/09/2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//

#import "Route.h"

@interface Route (TransformableAttributes)

#pragma mark transformables

-(NSArray *)coordinates;
-(void)setCoordinates:(id)coordinates;

@end
