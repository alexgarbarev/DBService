//
//  NSObject+DBScheme.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 14.04.14.
//
//

#import "NSObject+DBScheme.h"
#import "DBCoding.h"
#import "DBCodingScheme.h"

@implementation NSObject (DBScheme)

static id<DBScheme> schemeForCurrentClass;

+ (id<DBScheme>)scheme
{
    if ([self conformsToProtocol:@protocol(DBCoding)]) {
        if (!schemeForCurrentClass) {
            schemeForCurrentClass = [[DBCodingScheme alloc] initWithDBCodingClass:self];
        }
        return schemeForCurrentClass;
    } else {
        return nil;
    }
}

@end
