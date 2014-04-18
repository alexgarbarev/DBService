//
//  DBObjectDecoder.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBDatabaseProvider.h"

@class FMResultSet;
@class DBEntity;
@class DBScheme;

typedef NSUInteger DBObjectDecoderOptions;

/**
 *  DBObjectFetcher creates objects from FMResultSet using DBEntity, DBScheme(for resolving relations) and DBDatabaseProvider for additional fetches
 */
@interface DBObjectFetcher : NSObject

- (instancetype)initWithScheme:(DBScheme *)scheme;

- (id)fetchObjectFromResultSet:(FMResultSet *)resultSet entity:(DBEntity *)entity provider:(DBDatabaseProvider *)fetcher options:(DBObjectDecoderOptions)options;

- (id)fetchObjectWithId:(id)primaryKeyValue entity:(DBEntity *)entity provider:(DBDatabaseProvider *)fetcher;

@end
