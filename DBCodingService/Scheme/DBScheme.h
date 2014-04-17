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
@class DBEntityRelationRepresentation;

@interface DBScheme : NSObject

- (void)registerEntity:(DBEntity *)entity;
- (void)registerRelation:(DBEntityRelation *)relation;

/**
 * Enumerates all to-one relations (one-to-one and many-to-one) using block. 
 */
- (void)enumerateToOneRelationsFromEntity:(DBEntity *)entity usingBlock:(void(^)(DBEntityRelationRepresentation *relation, BOOL *stop))block;

- (void)enumerateRelationsFromEntity:(DBEntity *)entity usingBlock:(void(^)(DBEntityRelationRepresentation *, BOOL *stop))block;

- (DBEntity *)entityForClass:(Class)objectClass;

- (NSArray *)allEntities;

@end
