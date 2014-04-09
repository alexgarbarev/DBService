//
//  DBCoder.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import <Foundation/Foundation.h>

#import "DBTableConnection.h"

@protocol DBCoding;
@class DBCoder;

#define dbPrimaryKeyUndefined 0

typedef void(^DBCodingBlock)(DBCoder * table_coder, id object);
typedef void(^DBDecodingBlock)(DBCoder * table_decoder);

@interface DBCoder : NSObject
/** Indicate to skip zero values like 0 or "" in queries or not */
@property (nonatomic, readwrite) BOOL shouldSkipZeroValues;  /* Default: YES */

/* You can encode/decode NSString, NSNumber, NSData, NSDate as standart SQLite types and 'DBCoding'-compatible objects.
 * If you encode/decode DBCoding object, it means 'to-one' or 'to-many' relation. 
 * For example if you encode DBCoding object for column 'foreign_object' and save, QliqDBService initially saves 'to-one'
 * related objects and then set it's primary key for 'foreign_object' column when save root object  */

#pragma mark - Encoding

- (void)encodeObject:(id)object forColumn:(NSString *)column;
- (void)encodeObject:(id)object withSchemeClass:(Class)objectClass forColumn:(NSString *)column;
- (void)encodeObjects:(NSArray *)objects connection:(DBTableConnection *)connection coding:(DBCodingBlock)codingBlock;

/** Encode one-to-many objects.
  * @param foreignKeyColumn column in another table which refer to current objects row */
- (void)encodeObjects:(NSArray *)objects withForeignKeyColumn:(NSString *)foreignKeyColumn;

#pragma mark - Decoding

- (id)decodeObjectForColumn:(NSString *)column;
- (id)decodeObjectOfClass:(Class)objectClass forColumn:(NSString *)column;
- (id)decodeObjectOfClass:(Class)objectClass withSchemeClass:(Class)schemeClass forColumn:(NSString *)column;

/** Decode one-to-many objects */
- (NSArray *)decodeObjectsOfClass:(Class)schemeClass withForeignKeyColumn:(NSString *)foreignKeyColumn;

/** Decode many-to-many objects */
- (void)decodeObjectsFromConnection:(DBTableConnection *)connection decoding:(DBDecodingBlock)decodingBlock;

@end

@protocol DBCoding <NSObject>

/* Do not call this method directly to init object with coder.
 * Use objectOfClass:fromDecoder: in QliqDBService instead */
- (id)initWithDBCoder:(DBCoder *)decoder;

- (void)encodeWithDBCoder:(DBCoder *)coder;

- (NSString *)dbPKProperty; //KVC key for property which store primary key

+ (NSString *)dbTable;      // table name for object
+ (NSString *)dbPKColumn;   // primary key column name

@end
