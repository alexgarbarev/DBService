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
typedef id(^DBInsertingBlock)(id<DBCoding> object, Class objectClass, NSString *column);
typedef void(^DBInsertingForeignBlock)(id<DBCoding> object, NSString *foreignKey);


@interface DBCoder(DBService)

/* TODO: refactor this setters */
+ (BOOL) isCorrectPrimaryKey:(id) pkKey;
- (BOOL) havePrimaryKey;
- (void) setPrimaryKey:(id) pkValue;
- (id) primaryKey;
- (void) setPrimaryKeyColumn:(NSString *)pkColumn;
- (void) setTable:(NSString *)table;
- (void) setRootObjectClass:(Class)clazz;

/* one-to-one relations */
- (void) enumerateOneToOneRelatedObjects:(DBInsertingBlock)block;

/* many-to-many relations */
- (NSArray *)allManyToManyConnections;
- (void)enumerateManyToManyCodersForConnection:(DBTableConnection *)connection usingBlock:(void(^)(DBCoder *connectionCoder))block;
- (void)enumerateManyToManyRelationCoders:(void(^)(DBCoder *connection_coder, DBTableConnection *connection))block;

/* one-to-many relations */
- (NSArray *)allOneToManyForeignKeys;
- (void)enumerateOneToManyRelatedObjectsForKey:(NSString *)foreignKey withBlock:(void(^)(id<DBCoding>object))block;
- (void)enumerateOneToManyRelatedObjects:(DBInsertingForeignBlock)block;

/* Init for decoding */
- (id) initWithResultSet:(FMResultSet *) resultSet dbService:(DBCodingService *) service;

/* Init for encoding object */
- (id) initWithDBObject:(id<DBCoding>) rootObject;
- (id) initWithDBObject:(id<DBCoding>) rootObject as:(Class) objectClass;

/* Init for many-to-many relations */
- (id) initWithConnection:(DBTableConnection *) connection;

/* Access to statements */
- (void) updateStatement:(DBStatement) statement;
- (void) deleteStatement:(DBStatement) statement;
- (void) insertStatement:(DBStatement) statement replace:(BOOL) replace;

- (Class) rootObjectClass;

- (DBTableConnection *)connection;

@end