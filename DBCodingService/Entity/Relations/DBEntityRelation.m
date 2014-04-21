//
//  DBEntityRelation.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBEntityRelation.h"
#import "DBEntity.h"
#import "DBEntityRelationRepresentation.h"
#import "DBEntityField.h"

@implementation DBEntityRelation

- (BOOL)isEqualToRelation:(DBEntityRelation *)relation
{
    //TODO: Implement right way
    return [self isEqual:relation];
}

- (DBEntityRelationRepresentation *)representationFromEntity:(DBEntity *)entity
{
    return [[DBEntityRelationRepresentation alloc] initWithRelation:self fromEntity:entity];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, relation from %@ to %@, connected on fields '%@' <-> '%@'>", [self class], self, [self fromEntity].objectClass, [self toEntity].objectClass, [self fromField].property, [self toField].property];
}

@end
