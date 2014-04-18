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


NSString *DBInvalidCircularRelationException = @"DBInvalidCircularRelationException";

#define CheckToOneRelation(field, entity) NSAssert(field.column && field.property, @"To-One relation must have column and property, but %@ have wrong relation on field %@",entity, field)

static void CheckCircularRelation(id object, DBEntityRelationRepresentation *relationRepresentation)
{
    id relatedObject = [object valueForKey:relationRepresentation.fromField.property];
    if (relatedObject && [relatedObject valueForKey:relationRepresentation.toField.property] != object) {
        [NSException raise:DBInvalidCircularRelationException format:@"Class %@ have circular relation with %@ class, but instances not points to each over (Property '%@' of %@ must point to %@ and property '%@' of %@ must point to %@)",relationRepresentation.fromEntity.objectClass, relationRepresentation.toEntity.objectClass, relationRepresentation.fromField.property, object, [object valueForKey:relationRepresentation.fromField.property], relationRepresentation.toField.property, [object valueForKey:relationRepresentation.fromField.property], object];
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

- (void)save:(id)object withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider completion:(void(^)(BOOL wasInserted, id objectId, NSError * error))completion
{
    [self save:object withEntity:entity provider:provider exceptRelations:nil completion:completion];
}

- (void)save:(id)object withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider exceptRelations:(NSSet *)relationsToExclude completion:(void(^)(BOOL wasInserted, id objectId, NSError * error))completion
{
    //0. Save as parent entity
    if (entity.parentRelation) {
        [self save:object withEntity:entity.parentRelation.parentEntity provider:provider exceptRelations:nil completion:nil];
    }
    
    NSError *error = nil;
    BOOL wasInserted = NO;
    id objectId = [object valueForKey:entity.primary.property];
    
    //1. Save one-to-one related objects
    NSSet *circularRelations = [self saveToOneRelatedObjectsInObject:object withEntity:entity provider:provider exceptRelations:relationsToExclude];
    
    //2. Save object itself
    if ([provider isExistsObject:object withEntity:entity]) {
        [provider updateObject:object withEntity:entity fields:[[entity fields] set] error:&error];
    } else {
        id insertedId = [provider insertObject:object withEntity:entity fields:[[entity fields] set] tryReplace:NO error:&error];
        if ([DBEntity isEmptyPrimaryKey:objectId] && insertedId) {
            objectId = insertedId;
            [object setValue:objectId forKey:entity.primary.property];
        }
        wasInserted = YES;
    }
    //3. Save one-to-many
    //4. Save many-to-many related objects
    
    //5. Save one-to-one circular references
    [self saveCircularRelations:circularRelations inObject:object withEntity:entity provider:provider];
    
    if (completion) {
        completion(wasInserted, objectId, error);
    }
}

#pragma mark - Saving to-one relations

- (NSSet *)saveToOneRelatedObjectsInObject:(id)object withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider exceptRelations:(NSSet *)relationsToExclude
{
    NSUInteger fieldsCount = entity.fields.count;
    
    NSMutableSet *circularRelations = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    NSMutableSet *fieldsToSave = [[NSMutableSet alloc] initWithCapacity:fieldsCount];
    
    [scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relationRep, BOOL *stop) {
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
                
                [self processOldValueForRelation:relationRep onObject:object provider:provider];
            }
        }
    }];
    
    for (DBEntityField *fromField in fieldsToSave) {
        id relatedObject = [object valueForKey:fromField.property];
        if (relatedObject) {
            [self save:relatedObject withEntity:[scheme entityForClass:[relatedObject class]] provider:provider exceptRelations:circularRelations completion:nil];
        }
    }
    
    
    return circularRelations;
}

- (void)processOldValueForRelation:(DBEntityRelationRepresentation *)relation onObject:(id)object provider:(DBDatabaseProvider *)provider
{
    id objectPrimaryKey = [object valueForKey:relation.fromEntity.primary.property];
    if (![DBEntity isEmptyPrimaryKey:objectPrimaryKey]) {
        
        id oldValueId = [provider valueForField:relation.fromField onEntity:relation.fromEntity withPrimaryKeyValue:objectPrimaryKey];
        
        if (oldValueId && ![oldValueId isKindOfClass:[NSNull class]]) {
            [self processChangeFromValueWithId:oldValueId entity:relation.toEntity nullifyField:relation.toField rule:relation.toEntityChangeRule provider:provider];
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

- (void)saveCircularRelations:(NSSet *)circularRelations inObject:(id)object withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider
{
    /* Save to-one related objects again, since 'object' now saved and we have its idenitifer */
    [circularRelations enumerateObjectsUsingBlock:^(DBEntityRelation *relation, BOOL *stop) {
        DBEntityRelationRepresentation *representation = [relation representationFromEntity:entity];
        id relatedObject = [object valueForKey:representation.fromField.property];
        if (relatedObject) {
            [provider updateObject:relatedObject withEntity:representation.toEntity fields:[NSSet setWithObject:representation.toField] error:nil];
        }
    }];
}


@end
