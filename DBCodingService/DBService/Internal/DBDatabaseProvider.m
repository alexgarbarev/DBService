//
//  DBObjectDecoderFetcher.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import "DBDatabaseProvider.h"
#import "DBQueryBuilder.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "DBEntity.h"
#import "DBEntityField.h"

@interface FMResultSet (DBDatabaseResult) <DBDatabaseResult>

@end

@implementation DBDatabaseProvider {
    DBQueryBuilder *queryBuilder;
    FMDatabase *db;
}

- (instancetype)initWithQueryBuilder:(DBQueryBuilder *)_queryBuilder database:(FMDatabase *)_db
{
    self = [super init];
    if (self) {
        queryBuilder = _queryBuilder;
        db = _db;
    }
    return self;
}

- (void)useDatabase:(FMDatabase *)_db
{
    db = _db;
}

- (id<DBDatabaseResult>)resultFromQuery:(NSString *)query withArgs:(NSArray *)args
{
    return [db executeQuery:query withArgumentsInArray:args];
}

- (id<DBDatabaseResult>)resultForPrimaryKeyValue:(id)primaryKey andEntity:(DBEntity *)entity
{
    DBQuery query = [queryBuilder queryToSelectEntity:entity withPrimaryKey:primaryKey];
    return [db executeQuery:query.query withArgumentsInArray:query.args];
}

- (void)updateObject:(id)object withEntity:(DBEntity *)entity fields:(NSSet *)fields error:(NSError **)error
{
    DBQuery query = [queryBuilder queryToUpdateObject:object withEntity:entity withFields:fields];
    
    BOOL success = [db executeUpdate:query.query withArgumentsInArray:query.args];
    
    if (!success) {
        [self setupSqlError:error action:@"updating" query:query];
    }
}

- (id)insertObject:(id)object withEntity:(DBEntity *)entity fields:(NSSet *)fields tryReplace:(BOOL)replace error:(NSError **)error
{
    id insertedId = nil;
    
    DBQuery query = [queryBuilder queryToInsertObject:object withEntity:entity withFields:fields tryReplace:replace];
    BOOL success = [db executeUpdate:query.query withArgumentsInArray:query.args];
    
    if (!success) {
        [self setupSqlError:error action:@"insertion" query:query];
    } else {
        insertedId = @([db lastInsertRowId]);
    }
    
    return insertedId;
}

- (BOOL)nullifyField:(DBEntityField *)field onEntity:(DBEntity *)entity withPrimaryKeyValue:(id)primaryKeyValue
{
    NSAssert(field && field.column, @"Can't nullify field, since field or column are nil");
    
    DBQuery query = [queryBuilder queryToNullifyField:field withEntity:entity primaryKeyValue:primaryKeyValue];
    return  [db executeUpdate:query.query withArgumentsInArray:query.args];
}

- (BOOL)deleteObjectWithId:(id)objectId withEntity:(DBEntity *)entity
{
    DBQuery query = [queryBuilder queryToDeleteObjectWithEntity:entity withPrimaryKey:objectId];
    return [db executeUpdate:query.query withArgumentsInArray:query.args];
}

- (BOOL)isExistsObject:(id)object withEntity:(DBEntity *)entity
{
    __block BOOL exist = NO;
    
    id primaryKeyValue = [object valueForKey:entity.primary.property];
    
    if (![DBEntity isEmptyPrimaryKey:primaryKeyValue]) {
        DBQuery query = [queryBuilder queryToSelectEntity:entity withPrimaryKey:primaryKeyValue];
        FMResultSet *result = [db executeQuery:query.query withArgumentsInArray:query.args];
        if ([result next]) {
            exist = YES;
        }
        [result close];
    }
    
    return exist;
}

- (id)valueForField:(DBEntityField *)field onEntity:(DBEntity *)entity withPrimaryKeyValue:(id)primaryKeyValue
{
    DBQuery query = [queryBuilder queryToSelectField:field withEntity:entity primaryKeyValue:primaryKeyValue];
    id oldValueId = nil;
    
    FMResultSet *result = [db executeQuery:query.query withArgumentsInArray:query.args];
    if ([result next]) {
        oldValueId = [result objectForColumnIndex:0];
    }
    [result close];
    
    return oldValueId;
}

- (id)latestPrimaryKeyForEntity:(DBEntity *)entity
{
    DBQuery query = [queryBuilder queryToSelectLatestPrimaryKeyForEntity:entity];
    FMResultSet *result = [db executeQuery:query.query];
    id lastKey = nil;
    if ([result next]) {
        lastKey = [result objectForColumnIndex:0];
    }
    [result close];
    return lastKey;
}

- (void)setupSqlError:(NSError **)error action:(NSString *)action query:(DBQuery)query
{
    if (error) {
        NSError * dbError = [db lastError];
        if (dbError) {
            *error = dbError;
        } else {
            NSString *description = [NSString stringWithFormat:@"Something gone wrong while %@ (query: %@, args: %@)",action, query.query, query.args];
            *error = [NSError errorWithDomain:@"com.dbservice" code:DBErrorCodeUnknown userInfo:@{ NSLocalizedDescriptionKey : description}];
        }
    }
}

@end
