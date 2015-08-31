//
//  XMPPManager.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/15.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "XMPPManager.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "DDXMLNode.h"

//  连接服务器的目的
typedef NS_ENUM(NSInteger, ConnectToServerPurpose) {
    ConnectToServerPurposeLogin, //  登陆
    ConnectToServerPurposeRegister, //  注册
};

#define tag_subcribe_alertView 100
@interface XMPPManager ()

    {
    NSMutableArray* _friendList;
    NSString* _userID;
    NSString* _userPS;
    void (^callblockRegister)(BOOL); // 注册回调
    void (^callblockLogin)(BOOL); //登陆回调
    void (^callblockAddFriend)(BOOL); //添加好友回调
    void (^callblockSendMessage)(BOOL); //发送消息回调
    void (^callblockConnect)(BOOL); //服务器连接回调
    void (^friendListcallblock)(NSArray*, NSString*);
    void (^messageListcallblock)(NSArray*, NSString*);
}
@property (nonatomic) ConnectToServerPurpose connectToServerPurpose;

@end

@implementation XMPPManager

+ (XMPPManager*)defaultManager
{
    static XMPPManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XMPPManager alloc] init];
        manager.userMessageList = [NSMutableArray arrayWithCapacity:0];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupStream];
    }
    return self;
}

#pragma mark------ 链接到 openfire
- (void)connectToOpenfireWithCallblock:(XMPPManagerCallBlock)callblock;
{
    callblockConnect = callblock;
    [self connectToOpenfire];
}

- (void)connectToOpenfire
{
    //  防止用户更改HostName 每次连接 set Host
    //  指定openfire服务器地址。
    self.xmppStream.hostName = kHostName;
    //  指定openfire服务的端口号，默认是5222。
    self.xmppStream.hostPort = kHostPort;

    [self connectToServerWithUser:_userID];
}
#pragma mark------  注册 ----------
- (void)registerWithUserName:(NSString*)userName
                    password:(NSString*)password
               WithCallblock:(XMPPManagerCallBlock)callblock
{
    callblockRegister = callblock;
    _userID = userName;
    _userPS = password;

    // 小号的方法
    self.connectToServerPurpose = ConnectToServerPurposeRegister;
    [self connectToServerWithUser:userName];
}

#pragma mark--- 登陆
- (void)loginWithUserName:(NSString*)userName
                 password:(NSString*)password
            WithCallblock:(XMPPManagerCallBlock)callblock;
{
    callblockLogin = callblock;
    _userID = userName;
    _userPS = password;

    self.connectToServerPurpose = ConnectToServerPurposeLogin;

    [self connectToServerWithUser:userName];
}
#pragma mark--- 登出
- (void)logout
{
    // 离线状态发送
    XMPPPresence* presence = [XMPPPresence presenceWithType:@"unavailable"];
    [self.xmppStream sendElement:presence];
    [self.xmppStream disconnect];
}

#pragma mark - 连接服务器
//  配置JID 连接服务器
- (void)connectToServerWithUser:(NSString*)user;
{
    //带着jid去链接服务器
    XMPPJID* jid = [XMPPJID jidWithUser:user domain:kDomin resource:kResource];
    self.xmppStream.myJID = jid;
    DLog(@"jid=%@", jid);
    //  如果已经存在一个连接，需要先断开当前连接，然后再建立新的连接。
    [self connectToServer];
}
// 连接到服务器
- (void)connectToServer
{
    //  如果已经存在一个连接，需要先断开当前连接，然后再建立新的连接。
    if ([self.xmppStream isConnected]) {
        [self logout];
    }

    NSError* error = nil;
    //  30秒超时时间
    [self.xmppStream connectWithTimeout:30.0f error:&error];
    if (error != nil) {
        DLog(@"%s__%d__|请求连接服务器失败：%@", __FUNCTION__, __LINE__,
            [error localizedDescription]);
        if (callblockConnect) {
            callblockConnect(NO);
        }
    }
}

#pragma mark-----服务器连接 回调
- (void)xmppStreamDidConnect:(XMPPStream*)sender
{
    DLog(@"xmppStreamDidConnect 服务器 已连接 JID = %@", sender.myJID);
    if (callblockConnect) {
        callblockConnect(YES);
    }
    switch (self.connectToServerPurpose) {
    case ConnectToServerPurposeLogin: //登陆
        [sender authenticateWithPassword:_userPS error:NULL];
        break;
    case ConnectToServerPurposeRegister: //注册
        [sender registerWithPassword:_userPS error:NULL];
        break;
    default:
        break;
    }
}




- (void)createReservedRoomWithJID:(NSString*)jid
{
    /*
     <iq from='crone1@shakespeare.lit/desktop'
     id='create1'
     to='coven@chat.shakespeare.lit'
     type='get'>
     <query xmlns='http://jabber.org/protocol/muc#owner'/>
     </iq>*/
    NSXMLElement* queryElement =
        [NSXMLElement elementWithName:@"query"
                                xmlns:@"http://jabber.org/protocol/muc#owner"];
    NSXMLElement* iqElement = [NSXMLElement elementWithName:@"iq"];
    [iqElement addAttributeWithName:@"type" stringValue:@"get"];
    [iqElement addAttributeWithName:@"from"
                        stringValue:[[NSUserDefaults standardUserDefaults]
                                        objectForKey:@"kMyJID"]];
    [iqElement
        addAttributeWithName:@"to"
                 stringValue:[NSString stringWithFormat:
                                           @"%@@conference.%@", jid,
                                       [[NSUserDefaults standardUserDefaults]
                                               objectForKey:@"kHost"]]];
    [iqElement addAttributeWithName:@"id" stringValue:@"createReservedRoom"];
    [iqElement addChild:queryElement];
    [self.xmppStream sendElement:iqElement];
}
#pragma mark - XMPPStreamDelegate

- (void)xmppStreamWillConnect:(XMPPStream*)sender
{
    DLog(@"xmppStreamWillConnect");
}

#pragma mark-----注册成功
// 可拿到 外部设置代理 触发
- (void)xmppStreamDidRegister:(XMPPStream*)sender
{
    if (callblockRegister) {
        callblockRegister(YES);
    }
    DLog(@"xmppStreamDidRegister 注册成功");
    [USER_DEFAULT setObject:[NSString stringWithFormat:@"%@@%@/%@", _userID,
                                      kHostName, kResource]
                     forKey:@"kMyJID"];
    [USER_DEFAULT setObject:_userPS forKey:@"kPS"];
    [USER_DEFAULT synchronize];
}
#pragma mark-----注册失败
- (void)xmppStream:(XMPPStream*)sender didNotRegister:(NSXMLElement*)error
{
    if (callblockRegister) {
        callblockRegister(NO);
    }
    [self showAlertView:@"当前用户已经存在,请直接登录"];
}
#pragma mark-----登陆成功  回调函数
- (void)xmppStreamDidAuthenticate:(XMPPStream*)sender
{
    DLog(@"登陆成功  回调函数");
    if (callblockLogin) {
        callblockLogin(YES);
    }
    // 发送上线状态
    XMPPPresence* presence = [XMPPPresence presence];

    [[self xmppStream] sendElement:presence];
}
#pragma mark-----没有验证
- (void)xmppStream:(XMPPStream*)sender didNotAuthenticate:(NSXMLElement*)error
{
    if (callblockLogin) {
        callblockLogin(NO);
    }
    DLog(@"didNotAuthenticate :密码校验失败，登录不成功,原因是：%@",
        [error XMLString]);
}

- (NSString*)xmppStream:(XMPPStream*)sender
    alternativeResourceForConflictingResource:(NSString*)conflictingResource
{
    DLog(@"alternativeResourceForConflictingResource: %@", conflictingResource);
    return @"XMPPIOS";
}

- (void)xmppStream:(XMPPStream*)sender
  socketDidConnect:(GCDAsyncSocket*)socket
{
    DLog(@"socketDidConnect 成功连接上");
}

#warning my method
#pragma mark - 添加好友
- (void)addFriendWithXMPPJID:(XMPPJID*)Jid
               WithCallblock:(XMPPManagerCallBlock)callblock
{
    callblockAddFriend = callblock;
    if ([self.xmppRosterStorage userForJID:Jid
                                xmppStream:self.xmppStream
                      managedObjectContext:[self rosterContext]]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"添加失败" message:@"该用户已经是好友" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    // 添加好友请求 (只是发出添加好有的请求)
    [self.xmppRoster subscribePresenceToUser:Jid];
}

#pragma mark -  发送消息

- (void)sendMessage:(MessageModel*)message
              toJID:(XMPPJID*)Jid
      WithCallblock:(XMPPManagerCallBlock)callblock
{
    callblockSendMessage = callblock;
    XMPPMessage* xmppMessage = [XMPPMessage messageWithType:@"chat" to:Jid];
    
    switch (message.messageType) {
        case ReceiveMessageText:
            [xmppMessage addBody:message.text];
            break;
        case ReceiveMessageImage: {
            NSData* data = UIImageJPEGRepresentation(message.image, 0.001);
            NSString* base64Image = [data base64EncodedString];
            NSMutableString* imageString =
            [[NSMutableString alloc] initWithString:kImage];
            [imageString appendString:base64Image];
            [xmppMessage addBody:imageString];
        } break;
        case ReceiveMessageVoice: {
            NSString* base64String = [message.voice base64EncodedString];
            NSMutableString* soundString =
            [[NSMutableString alloc] initWithString:kVoice];
            [soundString appendString:[self SecondChangeWithString:message.second]];
            [soundString appendString:base64String];
            [xmppMessage addBody:soundString];
        } break;
        default:
            break;
    }
    [self.xmppStream sendElement:xmppMessage];
}



#pragma mark - 好友列表获取
/*
 一个 IQ 请求：
 <iq type="get"
 　　from="xiaoming@example.com"
 　　to="example.com"
 　　id="1234567">
 　　<query xmlns="jabber:iq:roster"/>
 <iq />
 
 type 属性，说明了该 iq 的类型为 get，与 HTTP 类似，向服务器端请求信息
 from 属性，消息来源，这里是你的 JID
 to 属性，消息目标，这里是服务器域名
 id 属性，标记该请求 ID，当服务器处理完毕请求 get 类型的 iq 后，响应的 result 类型 iq 的 ID 与 请求 iq 的 ID 相同
 <query xmlns="jabber:iq:roster"/> 子标签，说明了客户端需要查询 roster
 */
- (void)fetchFriendListWithCompletion:(XMPPFetchCallBlock)callblock
{
    //    [self.xmppRoster fetchRoster];
    friendListcallblock = callblock;
    // 通过coredata获取好友列表
    NSManagedObjectContext* context = [self rosterContext];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                              inManagedObjectContext:context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    //添加排序规则
    NSSortDescriptor* sortD = [NSSortDescriptor sortDescriptorWithKey:@"jidStr" ascending:YES];
    [request setSortDescriptors:@[ sortD ]];
    [request setEntity:entity];

    __block NSError* error = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray* results = [context executeFetchRequest:request error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (callblock) {
                callblock(results, [error description]);
            }
        });
    });
    // 下面的方法是从服务器中查询获取好友列表
    //  // 创建iq节点
    //    NSXMLElement* iq = [NSXMLElement elementWithName:@"iq"];
    //    [iq addAttributeWithName:@"type" stringValue:@"get"];
    //    [iq addAttributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@", self.xmppStream.myJID]];
    //    [iq addAttributeWithName:@"to" stringValue:kDomin];
    //    [iq addAttributeWithName:@"id" stringValue:@"123"];
    //    // 添加查询类型
    //    NSXMLElement* query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    //    [iq addChild:query];
    //
    //    // 发送查询
    //    [_xmppStream sendElement:iq];
}
#pragma mark - 获取消息列表
- (void)fetchMessageListWithXMPPJID:(XMPPJID*)Jid Completion:(XMPPMessageListBlock)callblock
{
    NSManagedObjectContext* context = [self messageContext];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                              inManagedObjectContext:context];
    //    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    //    [request setEntity:entity];

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ AND bareJidStr == %@", self.xmppStream.myJID.bare, Jid.bare];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    __block NSError* error = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray* results = [context executeFetchRequest:fetchRequest error:&error];
        NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:results.count];
        for (XMPPMessageArchiving_Message_CoreDataObject* object in results) {
            [array addObject:object];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callblock) {
                callblock(array, [error description]);
            }
        });
    });
}

#pragma mark - 接受好友请求
/*
 一个 IQ 响应：
 <iq type="result"
 　　id="1234567"
 　　to="xiaoming@example.com">
 　　<query xmlns="jabber:iq:roster">
 　　　　<item jid="xiaoyan@example.com" name="小燕" />
 　　　　<item jid="xiaoqiang@example.com" name="小强"/>
 　　<query />
 <iq />
 type 属性，说明了该 iq 的类型为 result，查询的结果
 <query xmlns="jabber:iq:roster"/> 标签的子标签 <item />，为查询的子项，即为
 roster
 item 标签的属性，包含好友的 JID，和其它可选的属性，例如昵称等。
 */
- (BOOL)xmppStream:(XMPPStream*)sender didReceiveIQ:(XMPPIQ*)iq
{
    // 获取好友列表结果
    if ([iq.type isEqualToString:@"result"]) {
        NSXMLElement* query = [iq elementForName:@"query"];
        // 如果是注册，from和to都不为空，如果是删除，且待删除的用户在服务器中并没有，那么就没有from和to
        if ([iq attributeStringValueForName:@"from"] &&
            [iq attributeStringValueForName:@"to"]) {
            return YES;
        }

        if (query == nil) { // 用户不存在，直接从数据库删除即可

            return YES;
        }
        // 这种方式是通过手动发送IQ来查询好友列表的，不过这样操作不如使用XMPP自带的coredata操作方便
        //    NSString *thdID = [NSString stringWithFormat:@"%@", [iq
        //    attributeStringValueForName:@"id"] ];
        //    if ([thdID isEqualToString:kFetchBuddyListQueryID]) {
        //      NSXMLElement *query = [iq elementForName:@"query"];
        //
        //      NSMutableArray *result = [[NSMutableArray alloc] init];
        //      for (NSXMLElement *item in query.children) {
        //        NSString *jid = [item attributeStringValueForName:@"jid"];
        //        NSString *name = [item attributeStringValueForName:@"name"];
        //
        //        HYBBuddyModel *model = [[HYBBuddyModel alloc] init];
        //        model.jid = jid;
        //        model.name = name;
        //
        //        [result addObject:model];
        //      }
        //
        //      if (self.buddyListBlock) {
        //        self.buddyListBlock(result, nil);
        //      }
        //
        //      return YES;
        //    }
    }
    // 删除好友需要先查询，所以会进入到此代理回调函数中，如果type=@"set",
    // 说明是更新操作，即删除好友或者添加好友查询
    else if ([iq.type isEqualToString:@"set"]) {
        NSXMLElement* query = [iq elementForName:@"query"];
        for (NSXMLElement* item in query.children) {
            NSString* ask = [item attributeStringValueForName:@"ask"];
            NSString* subscription =
                [item attributeStringValueForName:@"subscription"];
            if ([ask isEqualToString:@"unsubscribe"] && ![subscription isEqualToString:@"none"]) { // 删除好友成功
                //                if (self.completionBlock) {
                //                    self.completionBlock(YES, nil);
                //                }
                return YES;
            }
            // 请求添加好友，但是查询没有结果，表示用户不存在
            // none表示未确认
            else if ([ask isEqualToString:@"subscribe"] &&
                [subscription isEqualToString:@"none"]) {
                //                if (self.completionBlock) {
                //                    self.completionBlock(YES,
                //                    @"发送添加好友请求成功");
                //                }
                return YES;
            }
            else if (![subscription
                         isEqualToString:@"none"]) { // 添加好友请求，查询成功
                return YES;
            }
        }
    }

    return YES;
}

#pragma mark - 收到好友消息
- (void)xmppStream:(XMPPStream*)sender didReceiveMessage:(XMPPMessage*)message
{

    //程序运行在前台，消息正常显示

    MessageModel* model = [[MessageModel alloc] init];
    ReceiveMessageType type = 0;

    if ([message.body hasPrefix:kVoice]) {
        type = ReceiveMessageVoice;
        model.second = [[message.body substringWithRange:NSMakeRange([kVoice length], 2)] integerValue];
        //这是语音消息
        model.voice =
            [[message.body substringFromIndex:[kVoice length] + 2] base64DecodedData];
    }
    else if ([message.body hasPrefix:kImage]) {
        type = ReceiveMessageImage;
        model.image = [UIImage
            imageWithData:[[message.body substringFromIndex:
                                             [kImage length]] base64DecodedData]];
    }
    else {
        type = ReceiveMessageText;
        model.text = message.body;
    }
    if ([_delegate respondsToSelector:@selector(receivesMessage:
                                                WithFromUserJID:
                                                    MessageType:)]) {
        [_delegate receivesMessage:model
                   WithFromUserJID:message.from
                       MessageType:type];
    }

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:message.from forKey:@"Jid"];
    [userInfo setObject:[NSString stringWithFormat:@"%ld", type] forKey:@"type"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageNotification object:model userInfo:userInfo];

    if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) { //如果程序在后台运行，收到消息以通知类型来显示
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"确认";
        localNotification.alertBody = [NSString stringWithFormat:@"提示: %@\n\n%@", @"新的消息", @"This is a text message"]; //通知主体
        //        localNotification.soundName = @"crunch.wav";//通知声音
        localNotification.applicationIconBadgeNumber = 1; //标记数
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification]; //发
    }
}

- (void)xmppStream:(XMPPStream*)sender didReceiveError:(NSXMLElement*)error
{
    DLog(@"接收信息时，出现异常: %@", error.description);
}
- (void)xmppStream:(XMPPStream*)sender didSendIQ:(XMPPIQ*)iq
{
    DLog(@"didSendIQ:%@", iq.description);
}
#pragma mark - 已发送消息
- (void)xmppStream:(XMPPStream*)sender didSendMessage:(XMPPMessage*)message
{
    if (callblockSendMessage) {
        callblockSendMessage(YES);
    }
    DLog(@"didSendMessage:%@", message.description);
}
- (void)xmppStream:(XMPPStream*)sender didSendPresence:(XMPPPresence*)presence
{
    DLog(@"didSendPresence:%@", presence.description);
}
- (void)xmppStream:(XMPPStream*)sender
   didFailToSendIQ:(XMPPIQ*)iq
             error:(NSError*)error
{
    DLog(@"didFailToSendIQ:%@", error.description);
}
#pragma mark - 消息发送失败
- (void)xmppStream:(XMPPStream*)sender
    didFailToSendMessage:(XMPPMessage*)message
                   error:(NSError*)error
{
    if (callblockSendMessage) {
        callblockSendMessage(NO);
    }

    DLog(@"didFailToSendMessage:%@", error.description);
}
- (void)xmppStream:(XMPPStream*)sender
    didFailToSendPresence:(XMPPPresence*)presence
                    error:(NSError*)error
{
    DLog(@"didFailToSendPresence:%@", error.description);
}
- (void)xmppStreamWasToldToDisconnect:(XMPPStream*)sender
{
    DLog(@"xmppStreamWasToldToDisconnect");
}
- (void)xmppStreamConnectDidTimeout:(XMPPStream*)sender
{
    DLog(@"xmpp stream 连接超时");
}
- (void)xmppStreamDidDisconnect:(XMPPStream*)sender withError:(NSError*)error
{
    DLog(@"xmppStreamDidDisconnect: %@", error.description);
}

#pragma mark - XMPPReconnectDelegate
- (void)xmppReconnect:(XMPPReconnect*)sender
    didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags
{
    DLog(@"didDetectAccidentalDisconnect:%u", connectionFlags);
}
- (BOOL)xmppReconnect:(XMPPReconnect*)sender
    shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags
{
    DLog(@"shouldAttemptAutoReconnect:%u", reachabilityFlags);
    return YES;
}
#pragma mark - xmpproom delegate
- (void)xmppRoomDidCreate:(XMPPRoom*)sender
{
    DLog(@"%@", sender);
}
- (void)xmppRoom:(XMPPRoom*)sender
    didFetchConfigurationForm:(NSXMLElement*)configForm
{
}

- (void)xmppRoom:(XMPPRoom*)sender
    willSendConfiguration:(XMPPIQ*)roomConfigForm
{
}

- (void)xmppRoom:(XMPPRoom*)sender didConfigure:(XMPPIQ*)iqResult
{
}
- (void)xmppRoom:(XMPPRoom*)sender didNotConfigure:(XMPPIQ*)iqResult
{
}

- (void)xmppRoomDidJoin:(XMPPRoom*)sender
{
}
- (void)xmppRoomDidLeave:(XMPPRoom*)sender
{
}

- (void)xmppRoomDidDestroy:(XMPPRoom*)sender
{
}

- (void)xmppRoom:(XMPPRoom*)sender
 occupantDidJoin:(XMPPJID*)occupantJID
    withPresence:(XMPPPresence*)presence
{
}
- (void)xmppRoom:(XMPPRoom*)sender
occupantDidLeave:(XMPPJID*)occupantJID
    withPresence:(XMPPPresence*)presence
{
}
- (void)xmppRoom:(XMPPRoom*)sender
    occupantDidUpdate:(XMPPJID*)occupantJID
         withPresence:(XMPPPresence*)presence
{
}

/**
 * Invoked when a message is received.
 * The occupant parameter may be nil if the message came directly from the room,
 *or from a non-occupant.
 **/

/*!
 *  收到消息
 *
 *  @param sender      <#sender description#>
 *  @param message     <#message description#>
 *  @param occupantJID <#occupantJID description#>
 */
- (void)xmppRoom:(XMPPRoom*)sender
    didReceiveMessage:(XMPPMessage*)message
         fromOccupant:(XMPPJID*)occupantJID
{
}

- (void)xmppRoom:(XMPPRoom*)sender didFetchBanList:(NSArray*)items
{
}
- (void)xmppRoom:(XMPPRoom*)sender didNotFetchBanList:(XMPPIQ*)iqError
{
}

- (void)xmppRoom:(XMPPRoom*)sender didFetchMembersList:(NSArray*)items
{
}
- (void)xmppRoom:(XMPPRoom*)sender didNotFetchMembersList:(XMPPIQ*)iqError
{
}

- (void)xmppRoom:(XMPPRoom*)sender didFetchModeratorsList:(NSArray*)items
{
}
- (void)xmppRoom:(XMPPRoom*)sender didNotFetchModeratorsList:(XMPPIQ*)iqError
{
}

- (void)xmppRoom:(XMPPRoom*)sender didEditPrivileges:(XMPPIQ*)iqResult
{
}
- (void)xmppRoom:(XMPPRoom*)sender didNotEditPrivileges:(XMPPIQ*)iqError
{
}

#pragma mark - 联系人名片
//到服务器上请求联系人名片信息
//- (void)fetchvCardTempForJID:(XMPPJID *)jid{
//
//}

//请求联系人的名片，如果数据库有就不请求，没有就发送名片请求
//- (void)fetchvCardTempForJID:(XMPPJID *)jid ignoreStorage:(BOOL)ignoreStorage

//获取联系人的名片，如果数据库有就返回，没有返回空，并到服务器上抓取

//- (XMPPvCardTemp *)vCardTempForJID:(XMPPJID *)jid shouldFetch:(BOOL)shouldFetch

//更新自己的名片信息
//- (void)updateMyvCardTemp:(XMPPvCardTemp *)vCardTemp;

//获取到一盒联系人的名片信息的回调
- (void)xmppvCardTempModule:(XMPPvCardTempModule*)vCardTempModule
        didReceivevCardTemp:(XMPPvCardTemp*)vCardTemp
                     forJID:(XMPPJID*)jid
{
    DLog(@"%s", __func__);
}

- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule*)vCardTempModule
{
}

- (void)xmppvCardTempModule:(XMPPvCardTempModule*)vCardTempModule failedToUpdateMyvCard:(NSXMLElement*)error
{
}

#pragma mark-----------------------------------------------------------
#pragma mark XMPPRosterDelegate  处理加好友
// 已经互为好友以后，会回调此
- (void)xmppRoster:(XMPPRoster*)sender
    didReceiveRosterItem:(NSXMLElement*)item
{
    NSString* subscription = [item attributeStringValueForName:@"subscription"];
    if ([subscription isEqualToString:@"both"]) {
        DLog(@"双方已经互为好友");
        if (friendListcallblock) {
            friendListcallblock(_friendList,nil);
        }
    }
}

// 添加好友同意后会进入此代理
- (void)xmppRoster:(XMPPRoster*)sender didReceiveRosterPush:(XMPPIQ*)iq
{
    DLog(@"添加成功!!!didReceiveRosterPush -> :%@", iq.description);

    DDXMLElement* query = [iq elementsForName:@"query"][0];
    DDXMLElement* item = [query elementsForName:@"item"][0];

    NSString* subscription =
        [[item attributeForName:@"subscription"] stringValue];
    // 对方请求添加我为好友且我已同意
    if ([subscription isEqualToString:@"from"]) { // 对方关注我
        DLog(@"我已同意对方添加我为好友的请求");
    }
    // 我成功添加对方为好友
    else if ([subscription isEqualToString:@"to"]) { // 我关注对方
        DLog(@"我" @"成" @"功" @"添"
            @"加对方为好友，即对方已经同意我添加好友的请"
            @"求");
    }
    else if ([subscription isEqualToString:@"remove"]) {
        // 删除好友
        DLog(@"删除好友");
    }
}

- (void)removeXMppUserXMPPJID:(XMPPJID*)Jid
                WithCallblock:(XMPPManagerCallBlock)callblock
{
    [self.xmppRoster removeUser:Jid];
}

#pragma mark - XMPPRosterDelegate  处理加好友
//处理加好友回调,(对方加 自己为好友时 触发)
- (void)xmppRoster:(XMPPRoster*)sender
    didReceivePresenceSubscriptionRequest:(XMPPPresence*)presence
{
    // 好友在线状态
    NSString* type = [presence type];
    // 发送请求者
    NSString* fromUser = [[presence from] user];
    // 接收者id
    NSString* user = _xmppStream.myJID.user;
    __weak typeof(self) weakSelf = self;
    callblockAddFriend = ^(BOOL isSuccessed) {
        if (!isSuccessed) {
            if (![fromUser isEqualToString:user]) {
                UIAlertView* alertView =
                    [[UIAlertView alloc] initWithTitle:presence.fromStr
                                               message:@"请求您为好友"
                                              delegate:weakSelf
                                     cancelButtonTitle:@"拒绝"
                                     otherButtonTitles:@"同意", nil];
                alertView.tag = tag_subcribe_alertView;
                [alertView show];
            }
        }
    };
}

#pragma mark--- 收到好友状态    收到好友上下线状态
- (void)xmppStream:(XMPPStream*)sender
didReceivePresence:(XMPPPresence*)presence
{
    NSString* presenceType = presence.type;

    NSString* userId = sender.myJID.user;
    NSString* presenceFromUser = presence.from.user;

    XMPPJID* jid =
        [XMPPJID jidWithUser:presenceFromUser
                      domain:kDomin
                    resource:kResource];
    DLog(@"%s%@", __func__, jid);
    if (![presenceFromUser isEqualToString:userId]) {
        // 用户在线
        if ([presenceType isEqualToString:@"available"]) {
            //在线
        }
        else if ([presenceType isEqualToString:@"unavailable"]) {
            //离线
        }
        else if ([presenceType isEqualToString:@"subscribe"]) {
            [self.xmppRoster acceptPresenceSubscriptionRequestFrom:jid
                                                    andAddToRoster:YES];
            if (callblockAddFriend) {
                callblockAddFriend(YES); //同意
            }
        }
        else if ([presenceType isEqualToString:@"unsubscribed"]) {
            if (callblockAddFriend) {
                callblockAddFriend(NO); //删除
            }

            [self.xmppRoster removeUser:jid];
        }
        else if ([presenceType isEqualToString:@"unsubscribe"]) {
            [self.xmppRoster removeUser:jid]; // 拒绝
        }
    }
}

#pragma mark - 获取好友列 delegate
// 开始获取好友列表
- (void)xmppRosterDidBeginPopulating:(XMPPRoster*)sender
{
    DLog(@"开始检索好友列表");
    _friendList = [NSMutableArray arrayWithCapacity:0];
}
// 获取好友列表 每获取一次就执行一次
- (void)xmppRoster:(XMPPRoster*)sender
    didRecieveRosterItem:(DDXMLElement*)item
{
    NSString* jidStr = [[item attributeForName:@"jid"] stringValue];
    DLog(@"正在检索好友:%@", item);
    NSString* relationship = [[item attributeForName:@"ask"] stringValue];
    if (relationship) {
        return;
    }

    XMPPJID* jid = [XMPPJID jidWithString:jidStr resource:kResource];
    //防止重复加入
    if ([_friendList containsObject:jid]) {
        return;
    }
    if (jid.user) {
        [_friendList addObject:jid];
    }
}
// 获取结束
- (void)xmppRosterDidEndPopulating:(XMPPRoster*)sender
{
    DLog(@"检索完毕");
    if ([_delegate respondsToSelector:@selector(receivesFriendList:)]) {
        [_delegate receivesFriendList:_friendList];
    }
    self.userFriendList = [NSMutableArray arrayWithArray:_friendList];
}

#pragma mark - my method
- (void)showAlertView:(NSString*)message
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"ok"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}
#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView*)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    XMPPJID* jid = [XMPPJID jidWithString:alertView.title];
    if (alertView.tag == tag_subcribe_alertView && buttonIndex == 0) {
        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:jid];
        [self.xmppRoster removeUser:jid];
    }
    else if (alertView.tag == tag_subcribe_alertView && buttonIndex == 1) {
        [[self xmppRoster] acceptPresenceSubscriptionRequestFrom:jid
                                                  andAddToRoster:YES];
    }
}

#pragma mark - Private
#pragma mark - Private
- (NSManagedObjectContext*)rosterContext
{
    return [_xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext*)capabilitesContext
{
    return [_xmppCapailitiesStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext*)messageContext
{
    return [_xmppMessageStorage mainThreadManagedObjectContext];
}


#pragma mark - xmpp 配置
- (void)setupStream
{
    self.xmppStream = [[XMPPStream alloc] init];
#if !TARGET_IPHONE_SIMULATOR
    // 设置此行为YES,表示允许socket在后台运行
    // 在模拟器上是不支持在后台运行的
    self.xmppStream.enableBackgroundingOnSocket = YES;
#endif
    
    // 设置自动断线重连 模块会监控意外断开连接并自动重连
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    [self.xmppReconnect activate:self.xmppStream];
    
    //好友相关
    // 配置花名册并配置本地花名册储存
    self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    self.xmppRoster =
    [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
    self.xmppRoster.autoFetchRoster = YES; //是否自动获取花名册
    // 是否自动同意添加好友
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    // 配置vCard存储支持，vCard模块结合vCardTempModule可下载用户Avatar
    self.xmppvCardStorage = [[XMPPvCardCoreDataStorage alloc] init];
    self.xmppvCardTempModule =
    [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
    self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc]
                                  initWithvCardTempModule:self.xmppvCardTempModule];
    
    // XMPP特性模块配置，用于处理复杂的哈希协议等
    self.xmppCapailitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] init];
    self.xmppCapabilities = [[XMPPCapabilities alloc]
                             initWithCapabilitiesStorage:_xmppCapailitiesStorage];
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    // 激活XMPP stream
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppRoster activate:self.xmppStream];
    [self.xmppvCardTempModule activate:self.xmppStream];
    [self.xmppvCardAvatarModule activate:self.xmppStream];
    [self.xmppCapabilities activate:self.xmppStream];
    
    // 消息相关
    self.xmppMessageStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    self.xmppMessageArchiving = [[XMPPMessageArchiving alloc]
                                 initWithMessageArchivingStorage:self.xmppMessageStorage];
    [self.xmppMessageArchiving setClientSideMessageArchivingOnly:YES];
    [self.xmppMessageArchiving activate:self.xmppStream];
    
    // 添加代理
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppMessageArchiving addDelegate:self
                             delegateQueue:dispatch_get_main_queue()];
    
    //    [self.xmppRoster activate:self.xmppStream];
    //    [self.xmppRoster addDelegate:self
    //    delegateQueue:dispatch_get_main_queue()];
    //
    //    //聊天信息相关
    //    XMPPMessageArchivingCoreDataStorage* xmppMessageArchivingCoreDataStorage
    //    = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    //    self.xmppMessageArchiving = [[XMPPMessageArchiving alloc]
    //    initWithMessageArchivingStorage:xmppMessageArchivingCoreDataStorage];
    //    [self.xmppMessageArchiving setClientSideMessageArchivingOnly:YES];
    //    [self.xmppMessageArchiving activate:self.xmppStream];
    //    [self.xmppMessageArchiving addDelegate:self
    //    delegateQueue:dispatch_get_main_queue()];
    
    //    [self connectToOpenfire];
    [self connectToOpenfireWithCallblock:^(BOOL isSuccessed){
        
    }];
}

//将 语音长度转化为字符串
- (NSString*)SecondChangeWithString:(NSInteger)second
{
    NSInteger m = second / 10;
    NSInteger s = second % 10;
    return [NSString stringWithFormat:@"%ld%ld", m, s];
}

//- (NSArray *)FilterFriends:(NSArray)

#pragma mark - XMPP协议错误码
- (NSString*)errorMessageWithErrorCode:(int)errorCode
{
    switch (errorCode) {
    case 302:
        return @"重定向";
    case 400:
        return @"无效的请求";
    case 401:
        return @"未经过授权认证";
    case 402: // 目前保留，未使用
        return @"";
    case 403:
        return @"服务器拒绝执行，可能是注册密码存储失败";
    case 404:
        return @"找不到匹配的资源";
    case 405:
        return @"可能是权限不够，不允许操作";
    case 406:
        return @"服务器不授受";
    case 407: // 目前未使用
        return @"";
    case 408: // 当前只用于Jabber会话管理器使用的零度认证模式中。
        return @"注册超时";
    case 409:
        return @"用户名已经存在"; // 冲突
    case 500:
        return @"服务器内部错误";
    case 501:
        return @"服务器不支持此功能，不可执行";
    case 502:
        return @"远程服务器错误";
    case 503:
        return @"无法提供此服务";
    case 504:
        return @"远程服务器超时";
    case 510:
        return @"连接失败";
    default:
        break;
    }

    return @"发生未知错误";
}

@end
