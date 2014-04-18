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

- (FMResultSet *)resultSetForPrimaryKeyValue:(id)primaryKey andEntity:(DBEntity *)entity
{
    DBQuery query = [queryBuilder queryToSelectEntity:entity withPrimaryKey:primaryKey];
    return [db executeQuery:query.query withArgumentsInArray:query.args];
}

@end
