//
//  DBObjectDecoderFetcher.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBDatabaseResult.h"

@class DBQueryBuilder;
@class FMDatabase;
@class DBEntity;
@class DBEntityField;

typedef enum { DBErrorCodeObjectIsNil = 100, DBErrorCodeObjectIsNotExist, DBErrorCodeUnknown } DBErrorCode;


@interface DBDatabaseProvider : NSObject

- (instancetype)initWithQueryBuilder:(DBQueryBuilder *)queryBuilder database:(FMDatabase *)db;

- (void)useDatabase:(FMDatabase *)db;

- (id<DBDatabaseResult>)resultForPrimaryKeyValue:(id)primaryKey andEntity:(DBEntity *)entity;
- (id<DBDatabaseResult>)resultFromQuery:(NSString *)query withArgs:(NSArray *)args;

- (void)updateObject:(id)object withEntity:(DBEntity *)entity fields:(NSSet *)fields error:(NSError **)error;
- (id)insertObject:(id)object withEntity:(DBEntity *)entity fields:(NSSet *)fields tryReplace:(BOOL)replace error:(NSError **)error;
- (BOOL)deleteObjectWithId:(id)objectId withEntity:(DBEntity *)entity;
- (BOOL)nullifyField:(DBEntityField *)field onEntity:(DBEntity *)entity withPrimaryKeyValue:(id)primaryKeyValue;
- (BOOL)isExistsObject:(id)object withEntity:(DBEntity *)entity;
- (id)valueForField:(DBEntityField *)field onEntity:(DBEntity *)entity withPrimaryKeyValue:(id)primaryKeyValue;

- (id)latestPrimaryKeyForEntity:(DBEntity *)entity;

@end
