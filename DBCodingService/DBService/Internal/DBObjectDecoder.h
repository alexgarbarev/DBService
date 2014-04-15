//
//  DBObjectDecoder.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

@class FMResultSet;
@class DBEntity;

@interface DBObjectDecoder : NSObject

- (id)decodeObjectFromResultSet:(FMResultSet *)resultSet withEntity:(DBEntity *)entity;

@end
