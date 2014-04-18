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

- (DBEntityField *)fieldWithColumn:(NSString *)column
{
    for (DBEntityField *field in self.fields) {
        if ([field.column isEqualToString:column]) {
            return field;
        }
    }
    return nil;
}

+ (BOOL)isEmptyPrimaryKey:(id)primaryKey
{
    return primaryKey == nil
    || ([primaryKey isKindOfClass:[NSNumber class]] && [primaryKey integerValue] == 0)
    || ([primaryKey isKindOfClass:[NSString class]] && [primaryKey length] == 0);
}


@end
