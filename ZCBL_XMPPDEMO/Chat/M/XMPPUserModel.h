//
//  XMPPUserModel.h
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/19.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPUserModel : NSObject <NSCoding>
/*!
 *  用户在线状态
 */
@property (nonatomic, assign) NSInteger state;
/*!
 *  用户头像
 */
@property (nonatomic, strong) NSString* userIcon;
/*!
 *  用户名字
 */
@property (nonatomic, strong) NSString* userName;
/*!
 *  用户账户创建时间
 */
@property (nonatomic, strong) NSString * createTime;

@end
