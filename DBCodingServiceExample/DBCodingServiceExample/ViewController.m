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
#import "Icon.h"
#import "DBService.h"
#import "DBScheme.h"
#import "DBEntity.h"
#import "DBEntityField.h"

#import "DBOneToOneRelation.h"

@interface ViewController ()

@end

@implementation ViewController {
    FMDatabaseQueue *queue;
    DBService *service;
}

- (void)createTables
{
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE message (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, text text)"];
        [db executeUpdate:@"CREATE TABLE attachment (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, messageId integer NOT NULL, comment text)"];
        [db executeUpdate:@"CREATE TABLE file (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, file_size integer NOT NULL, mime text, path text, icon_id INTEGER)"];
        [db executeUpdate:@"CREATE TABLE icon (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, file_id integer NOT NULL, path text)"];
        [db executeUpdate:@"CREATE TABLE attachment_file (id integer NOT NULL PRIMARY KEY AUTOINCREMENT, attachment_id integer NOT NULL, file_id integer NOT NULL)"];
    }];
}

- (DBScheme *)newScheme
{
    DBScheme *scheme = [[DBScheme alloc] init];
    
    DBEntity *fileEntity = [self fieldEntity];
    DBEntity *iconEntity = [self iconEntity];
    [scheme registerEntity:fileEntity];
    [scheme registerEntity:iconEntity];
    
    DBOneToOneRelation *relation = [DBOneToOneRelation new];
    relation.fromEntity = fileEntity;
    relation.fromField = [fileEntity fieldWithColumn:@"icon_id"];
    relation.toEntity = iconEntity;
    relation.toField = [iconEntity fieldWithColumn:@"file_id"];
    relation.toEntityDeleteRule = DBEntityRelationDeleteRuleDeny;
    
    [scheme registerRelation:relation];
    
    return scheme;
}

- (DBEntity *)fieldEntity
{
    DBEntity *fileEntity = [[DBEntity alloc] init];
    fileEntity.table = @"file";
    fileEntity.objectClass = [File class];
    
    NSMutableOrderedSet *fields = [NSMutableOrderedSet new];
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeInteger32;
        field.column = @"id";
        field.property = @"fileId";
        [fields addObject:field];
        
        fileEntity.primary = field;
    }
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeInteger32;
        field.column = @"file_size";
        field.property = @"fileSize";
        [fields addObject:field];
    }
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeString;
        field.column = @"mime";
        field.property = @"mime";
        [fields addObject:field];
    }
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeInteger32;
        field.column = @"path";
        field.property = @"filePath";
        [fields addObject:field];
    }
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeInteger32;
        field.column = @"icon_id";
        field.property = @"icon";
        [fields addObject:field];
    }
    fileEntity.fields = fields;
    
    return fileEntity;
}

- (DBEntity *)iconEntity
{
    DBEntity *iconEntity = [[DBEntity alloc] init];
    iconEntity.table = @"icon";
    iconEntity.objectClass = [Icon class];
    
    NSMutableOrderedSet *fields = [NSMutableOrderedSet new];
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeInteger32;
        field.column = @"id";
        field.property = @"iconId";
        [fields addObject:field];
        
        iconEntity.primary = field;
    }
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeInteger32;
        field.column = @"file_id";
        field.property = @"file";
        [fields addObject:field];
    }
    {
        DBEntityField *field = [DBEntityField new];
        field.type = DBEntityFieldTypeString;
        field.column = @"path";
        field.property = @"path";
        [fields addObject:field];
    }
    iconEntity.fields = fields;
    
    return iconEntity;
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
    
    
    service = [[DBService alloc] initWithDatabaseQueue:queue scheme:[self newScheme]];
    
    [self testSingleSaving];
    [self test_one_to_one];
    [self test_simple_fetch];
//    [self testOneToMany];
//    [self testManyToMany];
    
    [super viewDidLoad];
}

- (void)testSingleSaving
{
    File *file = [[File alloc] init];
    file.fileSize = 123;
    file.filePath = @"path/to/file";
    file.mime = @"jpeg";
    
    [service save:file completion:^(BOOL wasInserted, id objectId, NSError *error) {
        NSLog(@"saved (inserted=%d, id=%@, error=%@)",wasInserted, objectId, error);
    }];
    
    file = [[File alloc] init];
    file.fileSize = 333;
    file.filePath = @"path/to/file";
    file.mime = @"jpeg";
    
    [service save:file completion:^(BOOL wasInserted, id objectId, NSError *error) {
        NSLog(@"saved (inserted=%d, id=%@, error=%@)",wasInserted, objectId, error);
    }];

}

- (void)test_one_to_one
{
    File *file = [[File alloc] init];
    file.fileSize = 101;
    file.filePath = @"file with icon";
    file.mime = @"png";
    
    Icon *icon1 = [Icon new];
    icon1.path = @"icon!";
    icon1.file = file;
    file.icon = icon1;
    
    [service save:file completion:^(BOOL wasInserted, id objectId, NSError *error) {
        NSLog(@"saved (inserted=%d, id=%@, error=%@)",wasInserted, objectId, error);
    }];
    
    Icon *icon2 = [Icon new];
    icon2.path = @"icon2";
    icon2.file = file;
    file.icon = icon2;
    
    [service save:file completion:^(BOOL wasInserted, id objectId, NSError *error) {
        NSLog(@"saved (inserted=%d, id=%@, error=%@)",wasInserted, objectId, error);
    }];
}

- (void)test_simple_fetch
{
    File *file = [service fetchObjectWithId:@(3) andClass:[File class]];
    NSAssert(file.fileSize == 101, @"");
    NSAssert([file.mime isEqualToString:@"png"], @"");
}

//- (void) testOneToMany
//{
//    Attachment *attachment1 = [Attachment new];
//    attachment1.comment = @"Path1";
//    
//    Attachment *attachment2 = [Attachment new];
//    attachment2.comment = @"Path2";
//    
//    Message *message = [Message new];
//    message.text = @"Hello world";
//    message.attachments = @[attachment1, attachment2];
//    
//    [service save:message completion:nil];
//    
//    Message *message2 = [service objectWithId:@(message.messageId) andScheme:[Message scheme]];
//    Attachment *atach = [message2.attachments lastObject];
//    message2.attachments = @[atach];
//    
//    [service save:message2 completion:nil];
//    
//    message = [service reloadObject:message];
//    
//    NSAssert([message.attachments count] == 1, @"");
//    
//    [service deleteObject:message completion:nil];
//}
//
//- (void)testManyToMany
//{
//    File *file1 = [File new];
//    file1.mime = @"type/mime1";
//    file1.fileSize = 123;
//    file1.filePath = @"path";
//    
//    File *file2 = [File new];
//    file2.mime = @"type/mime2";
//    file2.fileSize = 321;
//    file2.filePath = @"path2";
//    
//    File *file3 = [File new];
//    file3.mime = @"type/mime3";
//    file3.fileSize = 111;
//    file3.filePath = @"path3";
//
//    Attachment *attachment = [Attachment new];
//    attachment.comment = @"Attachment with files";
//    attachment.files = @[file1, file2, file3];
//
//    Message *message = [Message new];
//    message.text = @"Hello attachments";
//    message.attachments = @[attachment];
//    
//    [service save:message completion:nil];
//    
//    Message *message2 = [service objectWithId:@(message.messageId) andScheme:[Message scheme]];
//    
//    NSAssert([message2.attachments count] == 1, nil);
//    Attachment *attachment2 = [[message2 attachments] lastObject];
//    
//    NSAssert([attachment2.files count] == 3, nil);
//    
//    attachment.files = @[file1, file3];
//    [service save:message completion:nil];
//    
//    message2 = [service reloadObject:message2];
//    attachment2 = [[message2 attachments] lastObject];
//    NSAssert([attachment2.files count] == 2, nil);
//    
//    [service deleteObject:message completion:nil];
//}


@end
