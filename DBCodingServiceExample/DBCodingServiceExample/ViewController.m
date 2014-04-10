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
        [db executeUpdate:@"CREATE TABLE attachment (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, messageId integer NOT NULL, path text)"];
        
    }];
}

- (void)viewDidLoad
{
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"database.sqlite"];
    BOOL databaseCreated = ![[NSFileManager defaultManager] fileExistsAtPath:dbPath];
        
    queue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
    
    if (databaseCreated) {
        [self createTables];
    }
    
    
    service = [[DBCodingService alloc] initWithDatabaseQueue:queue];
    
    
    Attachment *attachment1 = [Attachment new];
    attachment1.filePath = @"Path1";

    Attachment *attachment2 = [Attachment new];
    attachment2.filePath = @"Path2";

    Message *message = [Message new];
    message.text = @"Hello world";
    message.attachments = @[attachment1, attachment2];
    
    [service save:message completion:nil];
    
    Message *message2 = [service objectWithId:@(1) andClass:[Message class]];
    Attachment *atach = [message2.attachments lastObject];
    message2.attachments = @[atach];
    
    [service save:message2 completion:nil];
    [super viewDidLoad];
}


@end
