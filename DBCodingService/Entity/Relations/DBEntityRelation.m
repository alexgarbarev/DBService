//
//  DBEntityRelation.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBEntityRelation.h"
#import "DBEntity.h"

@implementation DBEntityRelation

- (BOOL)isEqualToRelation:(DBEntityRelation *)relation
{
    //TODO: Implement right way
    return [self isEqual:relation];
}

- (BOOL)isCircularWithRelation:(DBEntityRelation *)relation
{
    return [self.fromEntity isEqualToEntity:relation.toEntity] && [self.toEntity isEqualToEntity:relation.fromEntity];
}

@end
