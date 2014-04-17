//
//  DBObjectDecoderFetcher.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>

@class DBQueryBuilder;
@class FMDatabase;
@class FMResultSet;
@class DBEntity;

@interface DBObjectDecoderFetcher : NSObject

- (instancetype)initWithQueryBuilder:(DBQueryBuilder *)queryBuilder database:(FMDatabase *)db;

- (FMResultSet *)resultSetForPrimaryKeyValue:(id)primaryKey andEntity:(DBEntity *)entity;

@end
