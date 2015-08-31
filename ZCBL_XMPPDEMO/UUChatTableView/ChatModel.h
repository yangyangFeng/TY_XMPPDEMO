//
//  ChatModel.h
//  UUChatTableView
//
//  Created by shake on 15/1/6.
//  Copyright (c) 2015年 uyiuyao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatModel : NSObject

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic) BOOL isGroupChat;
/*!
 *  随机添加数据
 */
- (void)populateRandomDataSource;
/*!
 *  随机添加数据源
 *
 *  @param number
 */
- (void)addRandomItemsToDataSource:(NSInteger)number;
/*!
 *  添加指定数据
 *
 *  @param dic <#dic description#>
 */
- (void)addSpecifiedItem:(NSDictionary *)dic;

/*!
 *  将消息添加到上
 *
 *  @param dic 
 */
- (void)insertSpecifiedItem:(NSDictionary *)dic;
@end
