//
//  DBManyToManyRelation.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import "DBEntityRelation.h"

@class DBEntity;

@interface DBManyToManyRelation : DBEntityRelation

@property (nonatomic, strong) DBEntityField *fromEntityField;

///Catched automatically from toEntity
@property (nonatomic, readonly) DBEntityField *toEntityField;

@property (nonatomic, strong) NSString *relationTable;
@property (nonatomic, strong) NSString *fromEntityIdColumn;
@property (nonatomic, strong) NSString *toEntityIdColumn;

@end
