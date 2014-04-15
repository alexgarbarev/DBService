//
//  DBScheme.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

@class DBEntity;

@interface DBScheme : NSObject 

- (void)registerEntity:(DBEntity *)entity;

- (DBEntity *)entityForClass:(Class)objectClass;

- (NSArray *)allEntities;

@end
