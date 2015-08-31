//
//  XMPPManager.h
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/15.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
#import "MessageModel.h"
#import "XMPPUserModel.h"
typedef NS_ENUM(NSInteger, ReceiveMessageType) {
    ReceiveMessageText = 0, //  文本
    ReceiveMessageImage, //  图片
    ReceiveMessageVoice, //
};
typedef void (^XMPPManagerCallBlock)(BOOL isSuccessed);
typedef void (^XMPPFetchCallBlock)(NSArray* buddyList, NSString* errogMsg);
typedef XMPPFetchCallBlock XMPPMessageListBlock;
#define kText @"MessageText"
#define kImage @"MessageImage"
#define kVoice @"MessageVoice"
@protocol XMPPManagerDelegate <NSObject>
/*!
 *  接收到消息
 *
 *  @param message NSData 根据数据类型解码
 */
- (void)receivesMessage:(MessageModel*)message WithFromUserJID:(XMPPJID*)Jid MessageType:(ReceiveMessageType)type;
/*!
 *  接收好友列表
 *
 *  @param friendList XMPPJID对象
 */
- (void)receivesFriendList:(NSMutableArray*)friendList;
@end

@interface XMPPManager : NSObject <XMPPStreamDelegate, XMPPRosterDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) XMPPReconnect* xmppReconnect;
@property (nonatomic, strong) XMPPStream* xmppStream; //通信管道相当于一根电话线

// 花名册相关
@property (nonatomic, strong) XMPPRoster* xmppRoster; //  好友花名册
@property (nonatomic, strong) XMPPRosterCoreDataStorage* xmppRosterStorage;

// 名片相关
@property (nonatomic, strong) XMPPvCardCoreDataStorage* xmppvCardStorage;
@property (nonatomic, strong) XMPPvCardTempModule* xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule* xmppvCardAvatarModule;

// 性能相关
@property (nonatomic, strong) XMPPCapabilities* xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage* xmppCapailitiesStorage;

//消息相关
@property (strong, nonatomic) XMPPMessageArchiving* xmppMessageArchiving;
@property (strong, nonatomic) NSManagedObjectContext* messageArchivingManagedObjectContext;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage* xmppMessageStorage;

@property (nonatomic, assign) id<XMPPManagerDelegate> delegate;
//获得XMPPManager的单例方法
+ (XMPPManager*)defaultManager;

/*!
 *  连接服务器
 */
- (void)connectToOpenfireWithCallblock:(XMPPManagerCallBlock)callblock;

/*!
 *  取消和服务器的链接
 */
- (void)logout;

/*!
 *  注册方法
 *
 *  @param userName
 *  @param password
 */
- (void)registerWithUserName:(NSString*)userName password:(NSString*)password WithCallblock:(XMPPManagerCallBlock)callblock;
/*!
 *  登陆方法 //失败 暂无
 *
 *  @param userName
 *  @param password
 */
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password WithCallblock:(XMPPManagerCallBlock)callblock;
/*!
 *  添加好友
 *
 *  @param Jid 好友的JID
 */
- (void)addFriendWithXMPPJID:(XMPPJID*)Jid WithCallblock:(XMPPManagerCallBlock)callblock;
/*!
 *  发送消息
 *
 *  @param message 消息内容
 *  @param jid     要发送的对象
 */
- (void)sendMessage:(MessageModel*)message toJID:(XMPPJID*)Jid WithCallblock:(XMPPManagerCallBlock)callblock;
/*!
 *  删除好友
 *
 *  @param Jid
 *  @param callblock
 */
- (void)removeXMppUserXMPPJID:(XMPPJID*)Jid WithCallblock:(XMPPManagerCallBlock)callblock;

/*!
 *  获取好友列表
 *
 *  @param callblock
 */
- (void)fetchFriendListWithCompletion:(XMPPFetchCallBlock)callblock;

/*!
 *  获取消息列表
 *
 *  @param callblock
 */
- (void)fetchMessageListWithXMPPJID:(XMPPJID*)Jid Completion:(XMPPMessageListBlock)callblock;

/*!
 *  好友列表数据
 */
@property (nonatomic, strong) NSMutableArray* userFriendList;
/*!
 *  消息联系人
 */
@property (nonatomic, strong) NSMutableArray* userMessageList;
@end
