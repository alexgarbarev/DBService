//
//  DBParentRelation.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import "DBEntityRelation.h"

@interface DBParentRelation : NSObject

@property (nonatomic, strong) DBEntityField *childColumnField;
@property (nonatomic, strong) DBEntity *parentEntity;

@end
