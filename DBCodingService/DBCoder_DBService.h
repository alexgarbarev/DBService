//
//  DBCoder.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//
#import "FMDatabase.h"

@class DBCodingService;

typedef void(^DBStatement)(NSString * query, NSArray * args);
typedef id(^DBInsertingBlock)(id<DBCoding> object, Class objectClass);

@interface DBCoder(DBService)

- (void) encodingRootObjectBlock:(void(^)(void)) block;

+ (BOOL) isCorrectPrimaryKey:(id) pkKey;
- (BOOL) havePrimaryKey;
- (void) setPrimaryKey:(id) pkValue;
- (id) primaryKey;


- (void) enumerateToOneRelatedObjects:(DBInsertingBlock)block;

- (void) enumerateToManyRelationCoders:(void(^)(DBCoder * connection_coder))block;

/* Init for decoding */
- (id) initWithResultSet:(FMResultSet *) resultSet dbService:(DBCodingService *) service;

/* Init for encoding object */
- (id) initWithDBObject:(id<DBCoding>) rootObject;
- (id) initWithDBObject:(id<DBCoding>) rootObject as:(Class) objectClass;

/* Init for to-many relations */
- (id) initWithConnection:(DBTableConnection *) connection;

/* Access to statements */
- (void) updateStatement:(DBStatement) statement;
- (void) deleteStatement:(DBStatement) statement;
- (void) insertStatement:(DBStatement) statement replace:(BOOL) replace;

- (Class) rootObjectClass;

@end