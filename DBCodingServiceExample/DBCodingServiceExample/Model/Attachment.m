//
//  Attachment.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import "Attachment.h"
#import "File.h"
#import "DBScheme.h"

@implementation Attachment

- (DBTableConnection *)attachmentToFileConnection
{
    return [DBTableConnection connectionWithTable:@"attachment_file" relationPKColumn:@"id" encoderColumn:@"attachment_id" encodedObjectColumn:@"file_id"];
}

- (void)encodeWithDBCoder:(DBCoder *)coder
{
    [coder encodeObject:@(self.messageId) forColumn:@"messageId"];
    [coder encodeObject:self.comment forColumn:@"comment"];
    
    /* Many-To-Many encoding */
    DBTableConnection *connection = [self attachmentToFileConnection];
    [coder encodeObjects:self.files connection:connection coding:^(DBCoder *table_coder, File *object) {
        [table_coder encodeObject:@(self.attachmentId) forColumn:connection.encoderColumn];
        [table_coder encodeObject:object forColumn:connection.encodedObjectColumn];
    }];
}

- (id)initWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self) {
        self.messageId = [[decoder decodeObjectForColumn:@"messageId"] intValue];
        self.comment = [decoder decodeObjectForColumn:@"comment"];
        
        /* Many-To-Many decoding */
        NSMutableArray *files = [NSMutableArray new];
        DBTableConnection *connection = [self attachmentToFileConnection];
        [decoder decodeObjectsFromConnection:connection decoding:^(DBCoder *table_decoder) {
            File *object = [table_decoder decodeObjectWithScheme:[File scheme] forColumn:connection.encodedObjectColumn];
            [files addObject:object];
        }];
        self.files = files;
    }
    return self;
}


- (NSString *)dbPKProperty
{
    return @"attachmentId";
}

+ (NSString *)dbPKColumn
{
    return @"id";
}

+ (NSString *)dbTable
{
    return @"attachment";
}

+ (BOOL)dbShouldDeleteManyToManyRelatedObjectWithClass:(id)object withConnection:(DBTableConnection *)connection
{
    return [object isKindOfClass:[File class]];
}


@end
