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

- (DBEntityRelation *)relationForField:(DBEntityField *)field
{
    DBEntityRelation *result = nil;
    
    for (DBEntityRelation *relation in self.relations) {
        if ([relation.fromEntityField isEqualToField:field]) {
            result = relation;
            break;
        }
    }
    
    return result;
}

@end
