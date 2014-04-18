//
//  DBObjectDeleter.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>
@class DBEntity;
@class DBScheme;
@class DBDatabaseProvider;

@interface DBObjectDeleter : NSObject

- (instancetype)initWithScheme:(DBScheme *)scheme;

- (void)deleteObjectWithId:(id)primaryKey withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider error:(NSError **)error;

@end
