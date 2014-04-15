//
//  DBService.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBService.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "DBEntity.h"
#import "DBEntityField.h"
#import "DBEntityRelation.h"
#import "DBOneToOneRelation.h"
#import "DBOneToManyRelation.h"
#import "DBManyToManyRelation.h"
#import "DBScheme.h"
#import "DBQueryBuilder.h"

@interface DBService ()

@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) FMDatabase *database;

@property (nonatomic, strong) DBScheme *scheme;
@property (nonatomic, strong) DBQueryBuilder *queryBuilder;

@end

@implementation DBService

- (instancetype)initWithDatabase:(FMDatabase *)database scheme:(DBScheme *)scheme
{
    self = [super init];
    if (self) {
        self.database = database;
        self.scheme = scheme;
        [self commonDBServiceInit];
    }
    return self;
}

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)queue scheme:(DBScheme *)scheme
{
    self = [super init];
    if (self) {
        self.queue = queue;
        self.scheme = scheme;
        [self commonDBServiceInit];
    }
    return self;
}

- (void)commonDBServiceInit
{
    self.queryBuilder = [DBQueryBuilder new];
}

#pragma mark - Working with FMDB

- (void)executeBlock:(void(^)(FMDatabase *db))block
{
    if (self.queue) {
        [self.queue inDatabase:block];
    } else if (self.database) {
        block(self.database);
    } else {
        NSAssert(NO, @"Database is not set. Init with 'initWithDatabaseQueue:scheme:' or 'initWithDatabase:scheme:'.");
    }
}

- (BOOL)executeUpdate:(NSString *)query withArgumentsInArray:(NSArray *)args
{
    __block BOOL success;
    [self executeBlock:^(FMDatabase *db) {
        success = [db executeUpdate:query withArgumentsInArray:args];
    }];
    return success;
}

- (NSError *)lastError
{
    __block NSError *error;
    [self executeBlock:^(FMDatabase *db) {
        error = [db lastError];
    }];
    return error;
}

- (sqlite_int64)lastInsertRowId
{
    __block sqlite_int64 lastRowId;
    [self executeBlock:^(FMDatabase *db) {
        lastRowId = [db lastInsertRowId];
    }];
    return lastRowId;
}

#pragma mark - Saving

- (void)save:(id)object completion:(DBSaveCompletion)completion
{
    [self save:object exceptRelations:nil completion:completion];
}

- (void)save:(id)object exceptRelations:(NSSet *)relationsToExclude completion:(DBSaveCompletion)completion
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];

    NSError *error = nil;
    BOOL wasInserted = NO;
    id objectId = [object valueForKey:entity.primary.property];
    
    //1. Save one-to-one related objects
    NSSet *circularReferences = [self saveOneToOneRelatedObjectsInObject:object withEntity:entity exceptRelations:relationsToExclude];
    
    //2. Save object itself
    if ([self isExistsObject:object withEntity:entity]) {
        [self updateObject:object withEntity:entity error:&error];
    } else {
        id insertedId = [self insertObject:object withEntity:entity tryReplace:NO error:&error];
        if ([self.queryBuilder isEmptyPrimaryKey:objectId] && insertedId) {
            objectId = insertedId;
            [object setValue:objectId forKey:entity.primary.property];
        }
        wasInserted = YES;
    }
    //3. Save one-to-many
    //4. Save many-to-many related objects
    
    //5. Save one-to-one circular references
    [self saveCircularRelations:circularReferences inObject:object withEntity:entity];
    
    if (completion) {
        completion(wasInserted, objectId, error);
    }
}

- (void)updateObject:(id)object withEntity:(DBEntity *)entity error:(NSError **)error
{
    DBQuery query = [self.queryBuilder queryToUpdateObject:object withEntity:entity];
    
    BOOL success = [self executeUpdate:query.query withArgumentsInArray:query.args];
    
    if (!success) {
        [self setupSqlError:error action:@"updating" query:query];
    }
}

- (id)insertObject:(id)object withEntity:(DBEntity *)entity tryReplace:(BOOL)replace error:(NSError **)error
{
    id insertedId = nil;
    
    DBQuery query = [self.queryBuilder queryToInsertObject:object withEntity:entity tryReplace:replace];
    BOOL success = [self executeUpdate:query.query withArgumentsInArray:query.args];
    
    if (!success) {
        [self setupSqlError:error action:@"insertion" query:query];
    } else {
        insertedId = @([self lastInsertRowId]);
    }
    
    return insertedId;
}

- (NSSet *)saveOneToOneRelatedObjectsInObject:(id)object withEntity:(DBEntity *)entity exceptRelations:(NSSet *)relationsToExclude
{
    NSMutableSet *circularRelations = [NSMutableSet new];
    
    for (DBEntityRelation *relation in [entity relations]) {
        if ([relation isKindOfClass:[DBOneToOneRelation class]] && ![relationsToExclude containsObject:relation]) {
            DBEntityField *fromField = relation.fromEntityField;
            DBEntityField *toField = relation.toEntityField;
            
            if (fromField && toField) {
                [circularRelations addObject:relation];
            }

            if (fromField && fromField.property && fromField.column) {
                id relatedObject = [object valueForKey:fromField.property];
                [self save:relatedObject exceptRelations:circularRelations completion:nil];
            }
        }
    }
    
    return circularRelations;
}

- (void)saveCircularRelations:(NSSet *)relations inObject:(id)object withEntity:(DBEntity *)entity
{
    /* Save one-to-one related objects again, since 'object' now saved and we have its idenitifer */
    for (DBEntityRelation *relation in relations) {
        id relatedObject = [object valueForKey:relation.fromEntityField.property];
        [self save:relatedObject completion:nil];
    }
}

#pragma mark - Requests

- (BOOL)isExistsObject:(id)object withEntity:(DBEntity *)entity
{
    __block BOOL exist = NO;
    
    id primaryKeyValue = [object valueForKey:entity.primary.property];
    
    if (![self.queryBuilder isEmptyPrimaryKey:primaryKeyValue]) {
        [self executeBlock:^(FMDatabase *db) {
            DBQuery query = [self.queryBuilder queryToSelectEntity:entity withPrimaryKey:primaryKeyValue];
            FMResultSet *result = [db executeQuery:query.query withArgumentsInArray:query.args];
            if ([result next]) {
                exist = YES;
            }
            [result close];
        }];
    }
    
    return exist;
}

#pragma mark - Utils

- (void)setupSqlError:(NSError **)error action:(NSString *)action query:(DBQuery)query
{
    if (error) {
        NSError * dbError = [self lastError];
        if (dbError){
            *error = dbError;
        }else{
            NSString *description = [NSString stringWithFormat:@"Something gone wrong while %@ (query: %@, args: %@)",action, query.query, query.args];
            *error = [NSError errorWithDomain:@"com.dbservice" code:DBErrorCodeUnknown userInfo:@{ NSLocalizedDescriptionKey : description}];
        }
    }
}

@end
