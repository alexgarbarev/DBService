//
//  DBObjectDecoder.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBObjectDecoderFetcher.h"

@class FMResultSet;
@class DBEntity;
@class DBScheme;

typedef NSUInteger DBObjectDecoderOptions;

/**
 *  DBObjectDecoder creates objects from FMResultSet using DBEntity, DBScheme(for resolving relations) and DBObjectDecoderFetcher for additional fetches
 */
@interface DBObjectDecoder : NSObject

- (instancetype)initWithScheme:(DBScheme *)scheme;

- (id)decodeObjectFromResultSet:(FMResultSet *)resultSet withEntity:(DBEntity *)entity fetcher:(DBObjectDecoderFetcher *)fetcher options:(DBObjectDecoderOptions)options;

- (id)objectWithId:(id)primaryKeyValue entity:(DBEntity *)entity fromFetcher:(DBObjectDecoderFetcher *)fetcher;

@end
