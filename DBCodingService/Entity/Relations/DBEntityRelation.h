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

- (BOOL)isEqualToRelation:(DBEntityRelation *)relation;

- (BOOL)isCircularWithRelation:(DBEntityRelation *)relation;

@end
