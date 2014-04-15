//
//  DBOneToManyRelation.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import "DBEntityRelation.h"

@interface DBOneToManyRelation : DBEntityRelation

///Must be a field with nil column and collection typed property
@property (nonatomic, strong) DBEntityField *fromEntityField;

///Must be a field with column and optional property
@property (nonatomic, strong) DBEntityField *toEntityField;

@end
