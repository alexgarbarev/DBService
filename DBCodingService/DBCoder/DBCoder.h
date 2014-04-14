//
//  DBCoder.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import <Foundation/Foundation.h>

#import "DBTableConnection.h"
#import "DBCoding.h"
#import "DBScheme.h"

@protocol DBScheme;
@class DBCoder;

#define dbPrimaryKeyUndefined 0

typedef void(^DBCodingBlock)(DBCoder *table_coder, id object);
typedef void(^DBDecodingBlock)(DBCoder *table_decoder);

@interface DBCoder : NSObject

/** Indicate to skip zero values like 0 or "" in queries or not */
@property (nonatomic, readwrite) BOOL shouldSkipZeroValues;  /* Default: YES */

/* You can encode/decode NSString, NSNumber, NSData, NSDate as standart SQLite types and 'DBCoding'-compatible objects.
 * If you encode/decode DBCoding object, it means 'to-one' or 'to-many' relation. 
 * For example if you encode DBCoding object for column 'foreign_object' and save, QliqDBService initially saves 'to-one'
 * related objects and then set it's primary key for 'foreign_object' column when save root object  */

#pragma mark - Encoding

/** Encode one-to-one and primitive objects */
- (void)encodeObject:(id)object forColumn:(NSString *)column;
- (void)encodeObject:(id)object withScheme:(id<DBScheme>)scheme forColumn:(NSString *)column;

/** Encode many-to-many objects */
- (void)encodeObjects:(NSArray *)objects connection:(DBTableConnection *)connection coding:(DBCodingBlock)codingBlock;

/** Encode one-to-many objects.
  * @param foreignKeyColumn column in another table which refer to current objects row */
- (void)encodeObjects:(NSArray *)objects withForeignKeyColumn:(NSString *)foreignKeyColumn;

#pragma mark - Decoding

- (id)decodeObjectForColumn:(NSString *)column;
- (id)decodeObjectWithScheme:(id<DBScheme>)scheme forColumn:(NSString *)column;

/** Decode one-to-many objects */
- (NSArray *)decodeObjectsWithScheme:(id<DBScheme>)scheme withForeignKeyColumn:(NSString *)foreignKeyColumn;

/** Decode many-to-many objects */
- (void)decodeObjectsFromConnection:(DBTableConnection *)connection decoding:(DBDecodingBlock)decodingBlock;

@end
