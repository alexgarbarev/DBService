//
//  DBOneToOneRelation.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import "DBEntityRelation.h"

@interface DBOneToOneRelation : DBEntityRelation

@property (nonatomic, strong) DBEntityField *fromEntityField;

///Catched automatically from toEntity
@property (nonatomic, readonly) DBEntityField *toEntityField;

@end
