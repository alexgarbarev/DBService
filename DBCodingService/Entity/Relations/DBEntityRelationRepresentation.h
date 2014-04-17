//
//  DBEntityRelationRepresentation.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBEntityRelation.h"

typedef enum {
    DBEntityRelationTypeOneToOne,
    DBEntityRelationTypeOneToMany,
    DBEntityRelationTypeManyToOne,
    DBEntityRelationTypeManyToMany
} DBEntityRelationType;

/**
 * DBEntityRelationRepresentation - object which represent DBEntityRelation from entity point of view.
 * i.e. fromEntity is always entity provided at init method, so relation is reversed if needed, plus 
 * you always can access to original relation via 'relation' property.
 */
@interface DBEntityRelationRepresentation : NSObject

@property (nonatomic, weak) DBEntityRelation *relation;

- (instancetype)initWithRelation:(DBEntityRelation *)relation fromEntity:(DBEntity *)fromEntity;

- (DBEntityRelationType)type;

- (DBEntity *)fromEntity;
- (DBEntityField *)fromField;
- (DBEntityRelationChangeRule)fromEntityChangeRule;
- (DBEntityRelationDeleteRule)fromEntityDeleteRule;

- (DBEntity *)toEntity;
- (DBEntityField *)toField;
- (DBEntityRelationChangeRule)toEntityChangeRule;
- (DBEntityRelationDeleteRule)toEntityDeleteRule;

@end
