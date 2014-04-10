//
//  File.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import "File.h"
#import "DBCoder.h"

@implementation File

- (void)encodeWithDBCoder:(DBCoder *)coder
{
    [coder encodeObject:self.filePath forColumn:@"path"];
    [coder encodeObject:@(self.fileSize) forColumn:@"file_size"];
    [coder encodeObject:self.mime forColumn:@"mime"];
}

- (id)initWithDBCoder:(DBCoder *)decoder
{
    self = [super init];
    if (self) {
        self.filePath = [decoder decodeObjectForColumn:@"path"];
        self.fileSize = [[decoder decodeObjectForColumn:@"file_size"] integerValue];
        self.mime = [decoder decodeObjectForColumn:@"mime"];
    }
    return self;
}

- (NSString *)dbPKProperty
{
    return @"fileId";
}

+ (NSString *)dbPKColumn
{
    return @"id";
}

+ (NSString *)dbTable
{
    return @"file";
}


@end
