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
@protocol DBObjectScheme;

@interface DBCoderData : NSObject

- (instancetype)initWithEncodingIgnoredColumns:(NSArray *)encodingIgnoredColumns;

- (NSArray *)allColumns;
- (NSUInteger)columnsCount;

- (id)valueForColumn:(NSString *)column;
- (id<DBObjectScheme>)valueSchemeForColumn:(NSString *)column;

- (void)setObject:(id)object withScheme:(id<DBObjectScheme>)scheme forColumn:(NSString *)column;
- (void)removeObjectForColumn:(NSString *)column;

- (void)setObjects:(NSArray *)objects withScheme:(id<DBObjectScheme>)scheme withForeignKey:(NSString *)key;
- (void)removeObjectsForForeignKey:(NSString *)key;

- (void)setCoders:(NSArray *)coders forConnection:(DBTableConnection *)connection;

- (NSArray *)allOneToManyForeignKeys;
- (void)enumerateOneToManyObjectsForKey:(NSString *)foreigKey usingBlock:(void(^)(id value, id<DBObjectScheme>scheme))enumerationBlock;

- (NSArray *)allManyToManyConnections;
- (void)enumerateManyToManyCodersForConnection:(DBTableConnection *)connection usingBlock:(void(^)(DBCoder *connectionCoder))block;

@end
