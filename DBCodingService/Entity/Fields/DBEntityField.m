//
//  DBEntityColumn.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import "DBEntityField.h"

@implementation DBEntityField

- (BOOL)isEqualToField:(DBEntityField *)field
{
    //TODO: Implement right way
    return [self isEqual:field];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<DBEntityField %p, (column = %@, property = %@)>",self, self.column, self.property];
}

@end
