//
//  DBObjectSaver.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import "DBObjectSaver.h"
#import "DBEntity.h"
#import "DBEntityField.h"
#import "DBEntityRelationRepresentation.h"
#import "DBParentRelation.h"
#import "DBDatabaseProvider.h"
#import "DBQueryBuilder.h"
#import "DBScheme.h"
#import "DBEntityRelation.h"
#import "DBStack.h"

typedef void(^DBObjectSaverCompletion)(BOOL wasInserted, id objectId, NSError * error);

typedef struct {
    BOOL wasInserted;
    __unsafe_unretained id objectId;
    __unsafe_unretained NSError *error;
} DBSavingResult;


@interface DBSaveContext : NSObject

@property (nonatomic, strong) DBDatabaseProvider *provider;
@property (nonatomic, strong) DBStack *stack;

@end

@implementation DBSaveContext
@end

NSString *DBInvalidCircularRelationException = @"DBInvalidCircularRelationException";

#define CheckToOneRelationField(field, entity) NSCAssert(field.column && field.property, @"To-One relation must have column and property, but %@ have wrong relation on field %@",entity, field)

static void CheckCircularRelation(id object, DBEntityRelationRepresentation *relationRepresentation)
{
    id relatedObject = [object valueForKey:relationRepresentation.fromField.property];
    if (relatedObject && [relatedObject valueForKey:relationRepresentation.toField.property] != object) {
        [NSException raise:DBInvalidCircularRelationException format:@"Class %@ have circular relation with %@ class, but instances not points to each over (Property '%@' of %@ must point to %@ and property '%@' of %@ must point to %@)",relationRepresentation.fromEntity.objectClass, relationRepresentation.toEntity.objectClass, relationRepresentation.fromField.property, object, [object valueForKey:relationRepresentation.fromField.property], relationRepresentation.toField.property, [object valueForKey:relationRepresentation.fromField.property], object];
    }
}

static void CheckToOneRelation(id object, DBEntityRelationRepresentation *representation)
{
    CheckToOneRelationField(representation.fromField, representation.fromEntity);
    
    BOOL isCircularRelation = representation.toField && representation.type == DBEntityRelationTypeOneToOne;
    if (isCircularRelation) {
        CheckToOneRelationField(representation.toField, representation.toEntity);
        CheckCircularRelation(object, representation);
    }
}

@implementation DBObjectSaver {
    DBScheme *scheme;
}

- (instancetype)initWithScheme:(DBScheme *)_scheme
{
    self = [super init];
    if (self) {
        scheme = _scheme;
    }
    return self;
}

- (void)save:(id)object withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider completion:(DBObjectSaverCompletion)completion
{
    DBSaveContext *context = [DBSaveContext new];
    context.provider = provider;
    context.stack = [DBStack new];
    
    [self save:object asEntity:entity withContext:context completion:completion];
}

- (void)save:(id)object asEntity:(DBEntity *)entity withContext:(DBSaveContext *)context completion:(DBObjectSaverCompletion)completion
{
    DBStackItem *stackItem = [DBStackItem new];
    stackItem.instance = object;
    stackItem.entity = entity;
    [context.stack push:stackItem];
    
    //1. Save as parent entity
    if (entity.parentRelation) {
        [self save:object asEntity:entity.parentRelation.parentEntity withContext:context completion:nil];
    }
    
    //2. Save to-one related objects
    [self saveToOneRelatedObjectsInObject:object withEntity:entity context:context];
    
    //3. Save object itself
    DBSavingResult result = [self saveOnlyObject:object withEntity:entity context:context];
    
    //Update primaryKey in stack item to get notification - key received
    [stackItem updatePrimaryKey];
    
    //4. Save to-many related objects
    [self saveToManyRelatedObjectsInObject:object withEntity:entity context:context];
    
    [context.stack pop];
    
    if (completion) {
        completion(result.wasInserted, result.objectId, result.error);
    }
}

#pragma mark - Saving to-one relations

- (void)saveToOneRelatedObjectsInObject:(id)object withEntity:(DBEntity *)entity context:(DBSaveContext *)context
{
    [scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relationRep, BOOL *stop) {

        if (relationRep.fromField) {
            DBStackItem *itemForRelation = [context.stack itemForRelation:relationRep.relation];
            /* Save related object if not currently saving */
            if (!itemForRelation) {
                
                CheckToOneRelation(object, relationRep);
                
                [self processOldValueForRelation:relationRep onObject:object context:context];
                
                /* Save related object */
                id relatedObject = [object valueForKey:relationRep.fromField.property];
                if (relatedObject) {
                    [context.stack useCurrentItemForRelation:relationRep.relation inBlock:^{
                        [self save:relatedObject asEntity:relationRep.toEntity withContext:context completion:nil];
                    }];
                }
            } else {
                /* Wait until related object saved itself, then update current object with related object id */
                [itemForRelation waitForPrimaryKeyInBlock:^(id primaryKey) {
                    id relatedObject = [object valueForKey:relationRep.fromField.property];
                    if (relatedObject) {
                        [context.provider updateObject:relatedObject withEntity:relationRep.toEntity fields:[NSSet setWithObject:relationRep.toField] error:nil];
                    }
                }];
            }
        }
    }];
}

#pragma mark - Saving object itself

- (DBSavingResult)saveOnlyObject:(id)object withEntity:(DBEntity *)entity context:(DBSaveContext *)context
{
    NSError *error = nil;
    id objectId = [object valueForKey:entity.primary.property];
    BOOL wasInserted = NO;

    if ([context.provider isExistsObject:object withEntity:entity]) {
        [context.provider updateObject:object withEntity:entity fields:[[entity fields] set] error:&error];
    } else {
        id insertedId = [context.provider insertObject:object withEntity:entity fields:[[entity fields] set] tryReplace:NO error:&error];
        if ([DBEntity isEmptyPrimaryKey:objectId] && insertedId) {
            objectId = insertedId;
            [object setValue:objectId forKey:entity.primary.property];
        }
        wasInserted = YES;
    }
    DBSavingResult result;
    result.error = error;
    result.objectId = objectId;
    result.wasInserted = wasInserted;
    return result;
}

#pragma mark - Saving to-many relations


- (void)saveToManyRelatedObjectsInObject:(id)object withEntity:(DBEntity *)entity context:(DBSaveContext *)context
{
    return;
    
    [scheme enumerateRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relation, BOOL *stop) {
        if (relation.type == DBEntityRelationTypeOneToMany || relation.type == DBEntityRelationTypeManyToMany) {
            if (relation.fromField.property) {
                id objects = [object valueForKey:relation.fromField.property];
                for (id relatedObject in objects) {
                    if (relation.type == DBEntityRelationTypeOneToMany) {

                    }
                }
            }
        }
    }];
}


#pragma mark - Processing old values

- (void)processOldValueForRelation:(DBEntityRelationRepresentation *)relation onObject:(id)object context:(DBSaveContext *)context
{
    id objectPrimaryKey = [object valueForKey:relation.fromEntity.primary.property];
    if (![DBEntity isEmptyPrimaryKey:objectPrimaryKey]) {
        
        id oldValueId = [context.provider valueForField:relation.fromField onEntity:relation.fromEntity withPrimaryKeyValue:objectPrimaryKey];
        
        if (oldValueId && ![oldValueId isKindOfClass:[NSNull class]]) {
            [self processChangeFromValueWithId:oldValueId entity:relation.toEntity nullifyField:relation.toField rule:relation.toEntityChangeRule provider:context.provider];
        }
    }
}

- (void)processChangeFromValueWithId:(id)oldValueId entity:(DBEntity *)entity nullifyField:(DBEntityField *)field rule:(DBEntityRelationChangeRule)rule provider:(DBDatabaseProvider *)provider
{
    switch (rule) {
        case DBEntityRelationChangeRuleNullify:
            [provider nullifyField:field onEntity:entity withPrimaryKeyValue:oldValueId];
            break;
        case DBEntityRelationChangeRuleCascade:
            [provider deleteObjectWithId:oldValueId withEntity:entity];
            break;
        default:
            break;
    }
}

#pragma mark - DBQueryBuilderValueProvider protocol

- (id)valueForField:(DBEntityField *)field onObject:(id)object withEntity:(DBEntity *)entity
{
    return nil;
}

@end
