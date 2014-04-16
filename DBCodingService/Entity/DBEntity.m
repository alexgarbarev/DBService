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

@end
