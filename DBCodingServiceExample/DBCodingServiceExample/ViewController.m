//
//  ViewController.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 1/10/13.
//
//

#import "ViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Message.h"
#import "Attachment.h"
#import "File.h"

@interface ViewController ()

@end

@implementation ViewController {
    FMDatabaseQueue *queue;
    DBCodingService *service;
}

- (void)createTables
{
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE message (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, text text)"];
        [db executeUpdate:@"CREATE TABLE attachment (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, messageId integer NOT NULL, comment text)"];
        [db executeUpdate:@"CREATE TABLE file (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, file_size integer NOT NULL, mime text, path text)"];
        [db executeUpdate:@"CREATE TABLE attachment_file (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, attachment_id integer NOT NULL, file_id integer NOT NULL)"];
    }];
}

- (void)viewDidLoad
{
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"database.sqlite"];
        [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    
    BOOL databaseCreated = ![[NSFileManager defaultManager] fileExistsAtPath:dbPath];

    
    queue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
    
    if (databaseCreated) {
        [self createTables];
    }
    
    
    service = [[DBCodingService alloc] initWithDatabaseQueue:queue];
    
    [self testOneToMany];
    [self testManyToMany];
    
    [super viewDidLoad];
}


- (void) testOneToMany
{
    Attachment *attachment1 = [Attachment new];
    attachment1.comment = @"Path1";
    
    Attachment *attachment2 = [Attachment new];
    attachment2.comment = @"Path2";
    
    Message *message = [Message new];
    message.text = @"Hello world";
    message.attachments = @[attachment1, attachment2];
    
    [service save:message completion:nil];
    
    Message *message2 = [service objectWithId:@(message.messageId) andClass:[Message class]];
    Attachment *atach = [message2.attachments lastObject];
    message2.attachments = @[atach];
    
    [service save:message2 completion:nil];
    
    message = [service reloadObject:message];
    
    NSAssert([message.attachments count] == 1, @"");
    
    [service deleteObject:message mode:DBModeAll completion:nil];
}

- (void)testManyToMany
{
    File *file1 = [File new];
    file1.mime = @"type/mime1";
    file1.fileSize = 123;
    file1.filePath = @"path";
    
    File *file2 = [File new];
    file2.mime = @"type/mime2";
    file2.fileSize = 321;
    file2.filePath = @"path2";
    
    File *file3 = [File new];
    file3.mime = @"type/mime3";
    file3.fileSize = 111;
    file3.filePath = @"path3";

    Attachment *attachment = [Attachment new];
    attachment.comment = @"Attachment with files";
    attachment.files = @[file1, file2, file3];

    Message *message = [Message new];
    message.text = @"Hello attachments";
    message.attachments = @[attachment];
    
    [service save:message completion:nil];
    
    Message *message2 = [service objectWithId:@(message.messageId) andClass:[Message class]];
    
    NSAssert([message2.attachments count] == 1, nil);
    Attachment *attachment2 = [[message2 attachments] lastObject];
    
    NSAssert([attachment2.files count] == 3, nil);
    
    attachment.files = @[file1, file3];
    [service save:message completion:nil];
    
    message2 = [service reloadObject:message2];
    attachment2 = [[message2 attachments] lastObject];
    NSAssert([attachment2.files count] == 2, nil);
    
    [service deleteObject:message mode:DBModeAll completion:nil];
}


@end
