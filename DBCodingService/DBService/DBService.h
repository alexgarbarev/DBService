//
//  DBService.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@class DBScheme;

typedef void(^DBSaveCompletion)(BOOL wasInserted, id objectId, NSError * error);
typedef void(^DBDeleteCompletion)(NSError *error);

@interface DBService : NSObject

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)queue scheme:(DBScheme *)scheme;

#pragma mark - Saving

/**
 * Insert or update object into database
 */
- (void)save:(id)object completion:(DBSaveCompletion)completion;

#pragma mark - Requests

/**
 * Return object of given class and objectId as primary key
 */
- (id)fetchObjectWithId:(id)objectId andClass:(Class)objectClass;

/**
 * Retuns array of fetched objects from SQL query. All relations are resolved.
 */
- (NSArray *)fetchObjectsOfClass:(Class)objectClass fromSQLQuery:(NSString *)query withArgs:(NSArray *)args;

/** 
 * it returns latest primary key. Useful for autoincrement PKs to know which PK will be insterted 
 */
- (id)latestPrimaryKeyForObjectClass:(Class)objectClass;

/** 
 * Returns object with same primary key and class, loaded from db
 */
- (id)reloadObject:(id)object;

#pragma mark - Deletion

- (void)deleteObject:(id)object completion:(DBDeleteCompletion)completion;

@end
