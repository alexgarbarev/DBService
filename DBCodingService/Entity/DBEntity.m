//
//  DBEntity.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import "DBEntity.h"
#import "DBEntityRelation.h"
#import "DBEntityField.h"

@implementation DBEntity

- (BOOL)isEqualToEntity:(DBEntity *)entity
{
    return [self isEqual:entity];
}

@end
