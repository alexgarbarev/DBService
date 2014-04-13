//
//  DBCoderData.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>

@class FMResultSet;
@class DBTableConnection;
@class DBCoder;
@protocol DBScheme;

@interface DBCoderData : NSObject

- (instancetype)initWithEncodingIgnoredColumns:(NSArray *)encodingIgnoredColumns;

- (NSArray *)allColumns;
- (NSUInteger)columnsCount;

- (id)valueForColumn:(NSString *)column;
- (id<DBScheme>)valueSchemeForColumn:(NSString *)column;

- (void)setObject:(id)object withScheme:(id<DBScheme>)scheme forColumn:(NSString *)column;
- (void)removeObjectForColumn:(NSString *)column;

- (void)setObjects:(NSArray *)objects withScheme:(id<DBScheme>)scheme withForeignKey:(NSString *)key;
- (void)removeObjectsForForeignKey:(NSString *)key;

- (void)setCoders:(NSArray *)coders forConnection:(DBTableConnection *)connection;

- (NSArray *)allOneToManyForeignKeys;
- (void)enumerateOneToManyObjectsForKey:(NSString *)foreigKey usingBlock:(void(^)(id value, id<DBScheme>scheme))enumerationBlock;

- (NSArray *)allManyToManyConnections;
- (void)enumerateManyToManyCodersForConnection:(DBTableConnection *)connection usingBlock:(void(^)(DBCoder *connectionCoder))block;

@end
