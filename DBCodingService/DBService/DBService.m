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
#import "DBEntityRelationRepresentation.h"
#import "DBScheme.h"
#import "DBQueryBuilder.h"
#import "DBObjectDecoderFetcher.h"
#import "DBObjectDecoder.h"

NSString *DBInvalidCircularRelationException = @"DBInvalidCircularRelationException";

#define CheckToOneRelation(field, entity) NSAssert(field.column && field.property, @"To-One relation must have column and property, but %@ have wrong relation on field %@",entity, field)

static void CheckCircularRelation(id object, DBEntityRelationRepresentation *relationRepresentation)
{
    id relatedObject = [object valueForKey:relationRepresentation.fromField.property];
    if (relatedObject && [relatedObject valueForKey:relationRepresentation.toField.property] != object) {
        [NSException raise:DBInvalidCircularRelationException format:@"Class %@ have circular relation with %@ class, but instances not points to each over (Property '%@' of %@ must point to %@ and property '%@' of %@ must point to %@)",relationRepresentation.fromEntity.objectClass, relationRepresentation.toEntity.objectClass, relationRepresentation.fromField.property, object, [object valueForKey:relationRepresentation.fromField.property], relationRepresentation.toField.property, [object valueForKey:relationRepresentation.fromField.property], object];
    }
}


@interface DBService ()

@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) FMDatabase *database;

@property (nonatomic, strong) DBScheme *scheme;
@property (nonatomic, strong) DBQueryBuilder *queryBuilder;
@property (nonatomic, strong) DBObjectDecoder *objectDecoder;

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
    self.objectDecoder = [[DBObjectDecoder alloc] initWithScheme:self.scheme];
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
    NSSet *circularRelations = [self saveToOneRelatedObjectsInObject:object withEntity:entity exceptRelations:relationsToExclude];
    
    //2. Save object itself
    if ([self isExistsObject:object withEntity:entity]) {
        [self updateObject:object withFields:[[entity fields] set] error:&error];
    } else {
        id insertedId = [self insertObject:object withFields:[[entity fields] set] tryReplace:NO error:&error];
        if ([self.queryBuilder isEmptyPrimaryKey:objectId] && insertedId) {
            objectId = insertedId;
            [object setValue:objectId forKey:entity.primary.property];
        }
        wasInserted = YES;
    }
    //3. Save one-to-many
    //4. Save many-to-many related objects
    
    //5. Save one-to-one circular references
    [self saveCircularRelations:circularRelations inObject:object withEntity:entity];
    
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

- (NSSet *)saveToOneRelatedObjectsInObject:(id)object withEntity:(DBEntity *)entity exceptRelations:(NSSet *)relationsToExclude
{
    NSUInteger fieldsCount = entity.fields.count;
    
    NSMutableSet *circularRelations = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    NSMutableSet *fieldsToSave = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    
    [self.scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relationRep, BOOL *stop) {
        DBEntityField *fromField = relationRep.fromField;
        DBEntityField *toField = relationRep.toField;
        if (![relationsToExclude containsObject:relationRep.relation])
        {
            if (fromField) {
                CheckToOneRelation(fromField, relationRep.fromEntity);

                BOOL isCircularRelation = toField && relationRep.type == DBEntityRelationTypeOneToOne;
                if (isCircularRelation) {
                    CheckToOneRelation(toField, relationRep.toEntity);
                    CheckCircularRelation(object, relationRep);
                    [circularRelations addObject:relationRep.relation];
                }
                
                [fieldsToSave addObject:fromField];
            }
        }
    }];
    
    for (DBEntityField *fromField in fieldsToSave) {
        id relatedObject = [object valueForKey:fromField.property];
        if (relatedObject) {
            [self save:relatedObject exceptRelations:circularRelations completion:nil];
        }
    }
    
    return circularRelations;
}

- (void)saveCircularRelations:(NSSet *)circularRelations inObject:(id)object withEntity:(DBEntity *)entity
{
    /* Save to-one related objects again, since 'object' now saved and we have its idenitifer */
    [circularRelations enumerateObjectsUsingBlock:^(DBEntityRelation *relation, BOOL *stop) {
        DBEntityRelationRepresentation *representation = [relation representationFromEntity:entity];
        id relatedObject = [object valueForKey:representation.fromField.property];
        if (relatedObject) {
            [self updateObject:relatedObject withFields:[NSSet setWithObject:representation.toField] error:nil];
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

#pragma mark - Fetches

- (id)fetchObjectWithId:(id)objectId andClass:(Class)objectClass
{
    return [self fetchObjectWithId:objectId andEntity:[self.scheme entityForClass:objectClass]];
}

- (NSArray *)fetchObjectsOfClass:(Class)objectClass fromSQLQuery:(NSString *)query withArgs:(NSArray *)args
{
    return [self fetchObjectsOfEntity:[self.scheme entityForClass:objectClass] fromSQLQuery:query withArgs:args];
}

- (id)fetchObjectWithId:(id)objectId andEntity:(DBEntity *)entity
{
    __block id object = nil;
    [self executeBlock:^(FMDatabase *db) {
        DBObjectDecoderFetcher *fetcher = [[DBObjectDecoderFetcher alloc] initWithQueryBuilder:self.queryBuilder database:db];
        object = [self.objectDecoder objectWithId:objectId entity:entity fromFetcher:fetcher];
    }];
    return object;
}

- (NSArray *)fetchObjectsOfEntity:(DBEntity *)entity fromSQLQuery:(NSString *)query withArgs:(NSArray *)args
{
    NSMutableArray *objects = [NSMutableArray new];
    [self executeBlock:^(FMDatabase *db) {
        DBObjectDecoderFetcher *fetcher = [[DBObjectDecoderFetcher alloc] initWithQueryBuilder:self.queryBuilder database:db];
        
        FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:args];
        while ([resultSet next]) {
            id object = [self.objectDecoder decodeObjectFromResultSet:resultSet withEntity:entity fetcher:fetcher options:0];
            [objects addObject:object];
        }
        [resultSet close];
        
    }];
    return objects;
}

- (id)reloadObject:(id)object
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];
    id primaryKey = [object valueForKey:entity.primary.property];
    NSAssert(![self.queryBuilder isEmptyPrimaryKey:primaryKey], @"Can't reload object, since object is not saved (empty primary key)");
    return [self fetchObjectWithId:primaryKey andEntity:entity];
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
