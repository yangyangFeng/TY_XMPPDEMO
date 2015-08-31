//
//  MessageModel.h
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/19.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPManager.h"
#import "XMPPUserModel.h"

@interface MessageModel : NSObject
/*!
 *  没有传值为nil
 *
 *  @param text
 *  @param image
 *  @param voice
 *
 *  @return
 */
+ (id)messageWithText:(NSString*)text Image:(UIImage*)image Voice:(NSData*)voice andSecond:(NSInteger)second;
/*!
 *  文本信息
 */
@property (nonatomic, strong) NSString* text;
/*!
 *  图片
 */
@property (nonatomic, strong) UIImage* image;
/*!
 *  音频NSData 数据 base64
 */
@property (nonatomic, strong) NSData* voice;
@property (nonatomic, assign) NSInteger second;
/*!
 *  返回消息类型
 */
@property (nonatomic, assign) NSInteger messageType;
/*!
 *  消息发送时间
 */
@property (nonatomic, strong) NSString* startTime;
/*!
 *  未读消息数
 */
@property (nonatomic, assign) NSInteger messageNumber;
/*!
 *  发送用户信息
 */
@property (nonatomic, strong) XMPPUserModel* userModel;

@property (nonatomic, strong) XMPPJID* fromJid;
@end
