//
//  Attachment.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBCoder.h"

@interface Attachment : NSObject <DBCoding>

@property (nonatomic) NSUInteger attachmentId;
@property (nonatomic) NSUInteger messageId;
@property (nonatomic, strong) NSString *filePath;

@end
