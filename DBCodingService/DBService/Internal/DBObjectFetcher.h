//
//  DBObjectDecoder.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBDatabaseProvider.h"
#import "DBDatabaseResult.h"

@class DBEntity;
@class DBScheme;

typedef NSUInteger DBObjectDecoderOptions;

/**
 *  DBObjectFetcher creates objects from FMResultSet using DBEntity, DBScheme(for resolving relations) and DBDatabaseProvider for additional fetches
 */
@interface DBObjectFetcher : NSObject

- (instancetype)initWithScheme:(DBScheme *)scheme;

- (id)fetchObjectFromResult:(id<DBDatabaseResult>)resultSet entity:(DBEntity *)entity provider:(DBDatabaseProvider *)fetcher;

- (id)fetchObjectWithId:(id)primaryKeyValue entity:(DBEntity *)entity provider:(DBDatabaseProvider *)fetcher;

@end
