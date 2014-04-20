//
//  DBStack.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 21.04.14.
//
//

#import "DBStackItem.h"

@class DBEntity;
@class DBEntityRelation;

@interface DBStack : NSObject

- (void)push:(DBStackItem *)item;
- (DBStackItem *)pop;

/* Used when fetching object to resolve circular references */
- (DBStackItem *)itemForEntity:(DBEntity *)entity withPrimaryKey:(id)primaryKeyValue;

/* Used when saving object, to obtain entity for related object in to-many relations */
- (DBStackItem *)itemForRelation:(DBEntityRelation *)relation;

/* Push item for relation. Item will be returned by itemForRelation in block */
- (void)useItem:(DBStackItem *)item forRelation:(DBEntityRelation *)relation inBlock:(void(^)())block;

- (void)useCurrentItemForRelation:(DBEntityRelation *)relation inBlock:(void(^)())block;


@end
