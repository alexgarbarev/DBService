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

typedef struct {
    __unsafe_unretained NSString *query;
    __unsafe_unretained NSArray *args;
} DBQuery;

@interface DBQueryBuilder : NSObject

- (DBQuery)queryToInsertObject:(id)object withEntity:(DBEntity *)entity tryReplace:(BOOL)replace;
- (DBQuery)queryToUpdateObject:(id)object withEntity:(DBEntity *)entity;
- (DBQuery)queryToDeleteObject:(id)object withEntity:(DBEntity *)entity;
- (DBQuery)queryToDeleteRelation:(DBManyToManyRelation *)relation fromObject:(id)fromObject toObject:(id)toObject;
- (DBQuery)queryToNullifyRelation:(DBEntityRelation *)relation fromObject:(id)fromObject toObject:(id)toObject;
- (DBQuery)queryToSelectEntity:(DBEntity *)entity withPrimaryKey:(id)primaryKeyValue;

@end
