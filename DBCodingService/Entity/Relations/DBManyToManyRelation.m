//
//  DBManyToManyRelation.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import "DBManyToManyRelation.h"
#import "DBEntity.h"

@implementation DBManyToManyRelation

@synthesize fromEntityField;


- (DBEntityField *)toEntityField
{
    DBEntityField *field = nil;
    for (DBEntityRelation *relation in [self.toEntity relations]) {
        if ([relation isCircularWithRelation:self]) {
            field = relation.fromEntityField;
            break;
        }
    }
    return field;
}

@end
