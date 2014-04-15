//
//  Attachment.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>

@interface Attachment : NSObject

@property (nonatomic) NSUInteger attachmentId;

@property (nonatomic) NSUInteger messageId;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSArray *files;

@end
