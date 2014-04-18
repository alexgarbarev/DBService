//
//  DBObjectDeleter.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import "DBObjectDeleter.h"

@implementation DBObjectDeleter {
    DBScheme *scheme;
}

- (instancetype)initWithScheme:(DBScheme *)_scheme
{
    self = [super init];
    if (self) {
        scheme = _scheme;
    }
    return self;
}

- (void)deleteObjectWithId:(id)primaryKey withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider error:(NSError **)error
{
    
}


@end
