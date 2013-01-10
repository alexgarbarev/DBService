//
//  DBTableConnection.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import <Foundation/Foundation.h>

@interface DBTableConnection : NSObject

@property (nonatomic, strong) NSString * table;
@property (nonatomic, strong) NSString * onColumn;
@property (nonatomic, strong) NSString * byColumn;

- (id) initWithTable:(NSString *) _table connectedOn:(NSString *) _onColumn by:(NSString *) _byColumn;
+ (id) connectionWithTable:(NSString *) table connectedOn:(NSString *) onColumn by:(NSString *) byColumn;

@end
