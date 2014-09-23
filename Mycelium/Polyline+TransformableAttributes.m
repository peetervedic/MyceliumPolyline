//
//  Polyline+TransformableAttributes.m
//  Mycelium
//
//  Created by Jonathon Bolitho on 25/08/2014.
//  Copyright (c) 2014 Mycelium. All rights reserved.
//

@implementation Polyline (TransformableAttributes)

#pragma mark Transformables
-(NSArray *)locationArray {
    if (!self.coordinates_data)
        return nil;
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:self.coordinates_data];
}

-(void)setCoordinates:(id)coordinates {
    NSData *coordinates_data = [NSKeyedArchiver archivedDataWithRootObject:coordinates];
    [self setValue:coordinates_data forKey:@"coordinates_data"];
}

@end