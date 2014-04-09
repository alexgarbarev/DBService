//
//  Attachment.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import "Attachment.h"

@implementation Attachment

- (void)encodeWithDBCoder:(DBCoder *)coder
{
    [coder encodeObject:@(self.messageId) forColumn:@"messageId"];
    [coder encodeObject:self.filePath forColumn:@"path"];
}

- (id)initWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self) {
        self.messageId = [[decoder decodeObjectForColumn:@"messageId"] intValue];
        self.filePath = [decoder decodeObjectForColumn:@"path"];
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


@end
