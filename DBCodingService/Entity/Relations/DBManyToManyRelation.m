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

- (NSString *)columnForEntity:(DBEntity *)entity
{
    NSString *column = nil;
    if ([entity isEqualToEntity:self.fromEntity]) {
        column = self.fromEntityIdColumn;
    } else if ([entity isEqualToEntity:self.toEntity]) {
        column = self.toEntityIdColumn;
    }
    return column;
}

@end
