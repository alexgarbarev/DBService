//
//  QliqDBService.h
//  qliq
//
//  Created by Aleksey Garbarev on 12/3/12.
//
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class FMDatabaseQueue;

#import "DBCoder.h"
#import "DBScheme.h"

typedef void(^DBSaveCompletion)(BOOL wasInserted, id objectId, NSError * error);
typedef void(^DBDeleteCompletion)(NSError * error);

typedef enum {DBModeSingle = 0, DBModeManyToMany = 1u << 1, DBModeOneToOne = 1u << 2, DBModeOneToMany = 1u << 3} DBMode;
#define DBModeAll (DBModeManyToMany|DBModeOneToOne|DBModeOneToMany)

typedef enum { DBErrorCodeObjectIsNil = 100, DBErrorCodeObjectIsNotExist, DBErrorCodeUnknown } DBErrorCode;

/* QliqDBService developed to provide common method to save, load and delete objects from SQLite.
 * Service work over FMDB.
 * All methods works synchonicaly. 
 * Service works only with objects which conforms DBCoding protocol. */
@interface DBCodingService : NSObject

- (id)initWithDatabase:(FMDatabase *)database;

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)queue;

/* 
 *   'as: (Class)' - Used to save one object as another object.
 *   It is used when objects are inherited. Because DBCoding compatible class contain all nessesary db schema to be stored
 *   For example when we saving User we save it as Contact then save as User because User inherited from Contact
 *
 *   mode (DBMode type) used to save, delete related objects. Implementation of initWithDecoder responds to loading related objects.
 *   On 'related objects' I mean 'to-one' and 'to-many' related 'DBCoding' ready objects. When we encoding 'DBCoding' object to some column,
 *   it means 'to-one' relation. When we using encode encodeObjects: it means 'to-many' relation.
*/

#pragma mark - Insertion/Updating

/** Save object (and it's dependencies) synchronically using its class as scheme (Class must conforms to DBCoding protocol) */
- (void)save:(id<DBCoding>)object completion:(DBSaveCompletion)completion;

/** Save object synchronically and dependecies specified by mode using specified scheme */
- (void)save:(id)object withScheme:(id<DBScheme>)scheme mode:(DBMode)mode completion:(DBSaveCompletion)completion;

#pragma mark - Queries

/** Fetch object with specified primaryKey and scheme */
- (id)objectWithId:(id)identifier andScheme:(id<DBScheme>)scheme;

/** Returns array of decoders for sql-query. To craete objects from decoders use objectOfClass:fromDecoder:
 * result of sql-query have to contain all columns which used by DBCoding objects in initWithDBCoder/encodeWithDBCoder methods
 * Usually it is SELECT * FROM object_table WHERE ...; */
- (NSArray *)decodersWithScheme:(id<DBScheme>)scheme fromSQLQuery:(NSString *)query withArgs:(NSArray *)args;

/** Returns array of object of given class, This methos is combination of decodersFromSQLQuery:withArgs and objectOfClass:fromDecoder: */
- (NSArray *)objectsWithScheme:(id<DBScheme>)scheme fromSQLQuery:(NSString *)query withArgs:(NSArray *)args;

#pragma mark - Construction objects from decoders

/** Creates object with his related objects by specified class and decoder */
- (id)objectWithScheme:(id<DBScheme>)scheme fromDecoder:(DBCoder *)decoder;

/** Creates object with his related objects by specified class, schemeClass and decoder */
- (id)objectOfClass:(Class)objectClass withSchemeClass:(Class)schemeClass fromDecoder:(DBCoder *) decoder;

#pragma mark - Deletions

/* Used object instead of only object's primary key to ablility delete related objects */
- (void)deleteObject:(id<DBCoding>)object completion:(DBDeleteCompletion)completion;
- (void)deleteObject:(id)object withScheme:(id<DBScheme>)scheme completion:(DBDeleteCompletion)completion;

#pragma mark - Utils

/** Returns object with same primary key and class, loaded from db */
- (id)reloadObject:(id<DBCoding>)object;

/** it returns latest primary key. Useful for autoincrement PKs to know which PK will be insterted */
- (id)latestPrimaryKeyForScheme:(id<DBScheme>)scheme;


@end
