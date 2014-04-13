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

static NSMutableDictionary *schemesCache;

+ (id<DBScheme>)scheme
{
    if ([self conformsToProtocol:@protocol(DBCoding)]) {
        
        if (!schemesCache) {
            schemesCache = [NSMutableDictionary new];
        }
        
        id <DBScheme>schemeForCurrentClass = schemesCache[NSStringFromClass(self)];
        
        if (!schemeForCurrentClass) {
            schemeForCurrentClass = [[DBCodingScheme alloc] initWithDBCodingClass:self];
            schemesCache[NSStringFromClass(self)] = schemeForCurrentClass;
        }
        
        return schemeForCurrentClass;
    } else {
        return nil;
    }
}

@end
