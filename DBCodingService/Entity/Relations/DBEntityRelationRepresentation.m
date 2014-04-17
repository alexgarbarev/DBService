//
//  DBEntityRelationRepresentation.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import "DBEntityRelationRepresentation.h"
#import "DBEntity.h"
#import "DBEntityField.h"

#import "DBOneToOneRelation.h"
#import "DBOneToManyRelation.h"
#import "DBManyToManyRelation.h"

@implementation DBEntityRelationRepresentation {
    BOOL shouldReverse;
    DBEntityRelationType type;
}

- (instancetype)initWithRelation:(DBEntityRelation *)relation fromEntity:(DBEntity *)fromEntity
{
    self = [super init];
    if (self) {
        self.relation = relation;
        
        if ([relation.toEntity isEqualToEntity:fromEntity]) {
            shouldReverse = YES;
        } else if ([relation.fromEntity isEqualToEntity:fromEntity]) {
            shouldReverse = NO;
        } else {
            NSAssert(NO, @"Can't create represenatation from %@ entity for %@ relation, because relation not contained entity", fromEntity, relation);
        }
        
        if ([relation isKindOfClass:[DBOneToOneRelation class]]) {
            type = DBEntityRelationTypeOneToOne;
        } else if ([relation isKindOfClass:[DBManyToManyRelation class]]) {
            type = DBEntityRelationTypeManyToMany;
        } else if ([relation isKindOfClass:[DBOneToManyRelation class]]) {
            if (shouldReverse) {
                type = DBEntityRelationTypeManyToOne;
            } else {
                type = DBEntityRelationTypeOneToMany;
            }
        } else {
            NSAssert(NO, @"Unrecognized relation class");
        }
        
    }
    return self;
}

static NSString *StringFromRelationType(DBEntityRelationType type)
{
    switch (type) {
        case DBEntityRelationTypeOneToOne: return @"one-to-one";
        case DBEntityRelationTypeOneToMany: return @"one-to-many";
        case DBEntityRelationTypeManyToOne: return @"many-to-one";
        case DBEntityRelationTypeManyToMany: return @"many-to-many";
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<DBEntityRelationRepresentation: %p, %@ relation from %@ to %@, connected on fields '%@' <-> '%@'>", self, StringFromRelationType(type), [self fromEntity].objectClass, [self toEntity].objectClass, [self fromField].property, [self toField].property];
}

- (DBEntityRelationType)type
{
    return type;
}

- (DBEntity *)fromEntity
{
    if (shouldReverse) {
        return self.relation.toEntity;
    } else {
        return self.relation.fromEntity;
    }
}

- (DBEntityField *)fromField
{
    if (shouldReverse) {
        return self.relation.toField;
    } else {
        return self.relation.fromField;
    }
}

- (DBEntityRelationChangeRule)fromEntityChangeRule
{
    if (shouldReverse) {
        return self.relation.toEntityChangeRule;
    } else {
        return self.relation.fromEntityChangeRule;
    }
}

- (DBEntityRelationDeleteRule)fromEntityDeleteRule
{
    if (shouldReverse) {
        return self.relation.toEntityDeleteRule;
    } else {
        return self.relation.fromEntityChangeRule;
    }
}

- (DBEntity *)toEntity
{
    if (shouldReverse) {
        return self.relation.fromEntity;
    } else {
        return self.relation.toEntity;
    }
}

- (DBEntityField *)toField
{
    if (shouldReverse) {
        return self.relation.fromField;
    } else {
        return self.relation.toField;
    }
}

- (DBEntityRelationChangeRule)toEntityChangeRule
{
    if (shouldReverse) {
        return self.relation.fromEntityChangeRule;
    } else {
        return self.relation.toEntityChangeRule;
    }
}

- (DBEntityRelationDeleteRule)toEntityDeleteRule
{
    if (shouldReverse) {
        return self.relation.fromEntityDeleteRule;
    } else {
        return self.relation.toEntityChangeRule;
    }
}


@end
