//
//  Message.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import "Message.h"
#import "Attachment.h"

@implementation Message

- (void)encodeWithDBCoder:(DBCoder *)coder
{
    /* Encoding object */
    [coder encodeObject:self.text forColumn:@"text"];
    /* Encoding One-To-Many relations*/
    [coder encodeObjects:self.attachments withForeignKeyColumn:@"messageId"];
}

- (id)initWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self) {
        self.text = [decoder decodeObjectForColumn:@"text"];
        self.attachments = [decoder decodeObjectsWithScheme:[Attachment scheme] withForeignKeyColumn:@"messageId"];
    }
    return self;
}

- (NSString *)dbPKProperty
{
    return @"messageId";
}

+ (NSString *)dbPKColumn
{
    return @"id";
}

+ (NSString *)dbTable
{
    return @"message";
}

@end
