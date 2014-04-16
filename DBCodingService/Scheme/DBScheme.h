//
//  DBScheme.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

@class DBEntity;
@class DBEntityRelation;
@class DBEntityField;

@interface DBScheme : NSObject

- (void)registerEntity:(DBEntity *)entity;
- (void)registerRelation:(DBEntityRelation *)relation;

/**
 * Enumerates all to-one relations (one-to-one and many-to-one) using block. 
 *
 * @c fromField - field in specified entity
 *
 * @c toEntity - another related entity
 *
 * @c toField - field in @c'toEntity' which refers back 
 *
 * @note 'toField' will haven't column but have property for many-to-one relations
 */
- (void)enumerateToOneRelationsFromEntity:(DBEntity *)entity usingBlock:(void(^)(DBEntityField *fromField, DBEntity *toEntity, DBEntityField *toField, BOOL *stop))block;

- (DBEntity *)entityForClass:(Class)objectClass;

- (NSArray *)allEntities;

@end
