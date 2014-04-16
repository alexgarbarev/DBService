//
//  DBEntityRelation.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DBEntityRelationDeleteRule) {
    DBEntityRelationDeleteRuleNoAction,
    DBEntityRelationDeleteRuleNullify,
    DBEntityRelationDeleteRuleCascade,
    DBEntityRelationDeleteRuleDeny
};

typedef NS_ENUM(NSInteger, DBEntityRelationChangeRule) {
    DBEntityRelationChangeRuleNullify,
    DBEntityRelationChangeRuleCascade,
};

@class DBEntity;
@class DBEntityField;

@interface DBEntityRelation : NSObject

///Entity which refer to another (toEntity)
@property (nonatomic, strong) DBEntity *fromEntity;
@property (nonatomic, strong) DBEntityField *fromEntityField;

///Entity referenced by 'toEntity'
@property (nonatomic, strong) DBEntity *toEntity;
@property (nonatomic, strong) DBEntityField *toEntityField;

///Rule to delete toEntity when deleting fromEntity
@property (nonatomic) DBEntityRelationDeleteRule toEntityDeleteRule;

///Rule for old values when changing value to another
@property (nonatomic) DBEntityRelationChangeRule toEntityChangeRule;

@property (nonatomic) DBEntityRelationDeleteRule fromEntityDeleteRule;
@property (nonatomic) DBEntityRelationChangeRule fromEntityChangeRule;

- (BOOL)isEqualToRelation:(DBEntityRelation *)relation;

- (BOOL)isCircularWithRelation:(DBEntityRelation *)relation;

@end
