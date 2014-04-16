//
//  DBSQLQueryBuilder.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBEntity.h"
#import "DBEntityRelation.h"
#import "DBManyToManyRelation.h"

@class DBScheme;

typedef struct {
    __unsafe_unretained NSString *query;
    __unsafe_unretained NSArray *args;
} DBQuery;

@interface DBQueryBuilder : NSObject

- (instancetype)initWithScheme:(DBScheme *)scheme;

- (DBQuery)queryToInsertObject:(id)object withFields:(NSSet *)fields tryReplace:(BOOL)replace;
- (DBQuery)queryToUpdateObject:(id)object withFields:(NSSet *)fields;
- (DBQuery)queryToDeleteObject:(id)object;
- (DBQuery)queryToDeleteRelation:(DBManyToManyRelation *)relation fromObject:(id)fromObject toObject:(id)toObject;
- (DBQuery)queryToNullifyRelation:(DBEntityRelation *)relation fromObject:(id)fromObject toObject:(id)toObject;
- (DBQuery)queryToSelectEntity:(DBEntity *)entity withPrimaryKey:(id)primaryKeyValue;

- (BOOL)isEmptyPrimaryKey:(id)primaryKey;

@end
