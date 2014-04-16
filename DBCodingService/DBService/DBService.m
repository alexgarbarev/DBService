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
    self.queryBuilder = [[DBQueryBuilder alloc] initWithScheme:self.scheme];
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
    [self save:object exceptFields:nil completion:completion];
}

- (void)save:(id)object exceptFields:(NSSet *)fieldsToExclude completion:(DBSaveCompletion)completion
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];

    NSError *error = nil;
    BOOL wasInserted = NO;
    id objectId = [object valueForKey:entity.primary.property];
    
    //1. Save one-to-one related objects
    NSSet *circularFields = [self saveToOneRelatedObjectsInObject:object withEntity:entity exceptFields:fieldsToExclude];
    
    NSSet *fieldsToSave = [[entity fields] set];
    //2. Save object itself
    if ([self isExistsObject:object withEntity:entity]) {
        [self updateObject:object withFields:fieldsToSave error:&error];
    } else {
        id insertedId = [self insertObject:object withFields:fieldsToSave tryReplace:NO error:&error];
        if ([self.queryBuilder isEmptyPrimaryKey:objectId] && insertedId) {
            objectId = insertedId;
            [object setValue:objectId forKey:entity.primary.property];
        }
        wasInserted = YES;
    }
    //3. Save one-to-many
    //4. Save many-to-many related objects
    
    //5. Save one-to-one circular references
    [self saveCircularFields:circularFields inObject:object withEntity:entity];
    
    if (completion) {
        completion(wasInserted, objectId, error);
    }
}

- (void)updateObject:(id)object withFields:(NSSet *)fields error:(NSError **)error
{
    DBQuery query = [self.queryBuilder queryToUpdateObject:object withFields:fields];
    
    BOOL success = [self executeUpdate:query.query withArgumentsInArray:query.args];
    
    if (!success) {
        [self setupSqlError:error action:@"updating" query:query];
    }
}

- (id)insertObject:(id)object withFields:(NSSet *)fields tryReplace:(BOOL)replace error:(NSError **)error
{
    id insertedId = nil;
    
    DBQuery query = [self.queryBuilder queryToInsertObject:object withFields:fields tryReplace:replace];
    BOOL success = [self executeUpdate:query.query withArgumentsInArray:query.args];
    
    if (!success) {
        [self setupSqlError:error action:@"insertion" query:query];
    } else {
        insertedId = @([self lastInsertRowId]);
    }
    
    return insertedId;
}

#pragma mark - Saving to-one relations

- (NSSet *)saveToOneRelatedObjectsInObject:(id)object withEntity:(DBEntity *)entity exceptFields:(NSSet *)fieldsToExclude
{
    NSUInteger fieldsCount = entity.fields.count;
    
    NSMutableSet *circularFromFields = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    NSMutableSet *circularToFields = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    NSMutableSet *fieldsToSave = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    
    [self.scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityField *fromField, DBEntity *toEntity, DBEntityField *toField, BOOL *stop) {
        if (![fieldsToExclude containsObject:fromField])
        {
            if (fromField && fromField.property && fromField.column) {
                
                BOOL isCircularRelation = toField && toField.column && toField.property;
                if (isCircularRelation) {
                    if ([[object valueForKey:fromField.property] valueForKey:toField.property] == object) {
                        [circularFromFields addObject:fromField];
                        [circularToFields addObject:toField];
                    }
                }
                
                [fieldsToSave addObject:fromField];
            }
        }
    }];
    
    for (DBEntityField *fromField in fieldsToSave) {
        id relatedObject = [object valueForKey:fromField.property];
        if (relatedObject) {
            [self save:relatedObject exceptFields:circularToFields completion:nil];
        }
    }
    
    return circularFromFields;
}

- (void)saveCircularFields:(NSSet *)fieldsToResave inObject:(id)object withEntity:(DBEntity *)entity
{
    /* Save to-one related objects again, since 'object' now saved and we have its idenitifer */
    [self.scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityField *fromField, DBEntity *toEntity, DBEntityField *toField, BOOL *stop) {
        if ([fieldsToResave containsObject:fromField]) {
            id relatedObject = [object valueForKey:fromField.property];
            if (relatedObject) {
                [self updateObject:relatedObject withFields:[NSSet setWithObject:toField] error:nil];
            }
        }
    }];
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
