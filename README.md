功能实现:

1.	登陆
2.	注册
3.	收发文本消息
4.	收发图片消息
5.	收发语音消息
6.	添加好友
7.	拒绝添加好友
8.	消息记录
9.	好友列表获取


1.	登陆详情:
登陆前,首先要配置服务器,和连接服务器的相关参数,例如:
	服务器ip地址
	域名
	开启服务器服务
确认XMPPStream 配置 正确,各项协议回调 已激活
初始化时 需要配置的类,否则服务无法检测
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

登陆时需要 验证密码
登陆时验证密码流程 : 首先连接到服务器  -> 将用户名拼接发送到服务器 -> 将密码发送给服务器等待验证
⇒	返回验证结果(正确或失败)
XMPP登陆 所用的方法 
{
// 连接服务器,调用此方法时,参数必须已设定 myJid .
-	(BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr

//登陆成功回调
-	(void)xmppStreamDidAuthenticate:(XMPPStream*)sender

// 验证密码 XMPPStream 对象调用
authenticateWithPassword 
// 登陆失败回调
- (void)xmppStream:(XMPPStream*)sender didNotAuthenticate:(NSXMLElement*)error

} 

2.	注册与登陆 流程相同 这里只将 涉及到得 方法 列出
{
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
#pragma mark-----注册成功
-	(void)xmppStreamDidRegister:(XMPPStream*)sender

#pragma mark-----注册失败
- (void)xmppStream:(XMPPStream*)sender didNotRegister:(NSXMLElement*)error)sender
}
	这里选着在 连接服务器成功回调里添加 注册密码发送.

3.	由于文本,图片,语音收发的实现原理基本一致.所以在这里将文本,图片,语音统一进行归纳,和方法整理
XMPP  即时通讯 是通过xml 流 传输. 下面是一段 基础文本 消息的 xml .
<message type="chat" to="97@zxcvbnm/8.100000"><body>2</body></message>
type = “chat” 是消息类型,此次xmpp 实现收发消息 都是通过这种类型 
to = 91@zxcvnm/8.10000 为消息接受者
body 作为消息载体,例子 xml 中 body 2 为消息内容

XMPPStream sendElement:
Xmppstream 调用sendElement 方法将 消息发送给服务器,再有服务器转发给消息接受者

图片: 将想要发送的图片压缩(为了节省流量,压缩后每张图片大约为 10k,压缩到最低)转整 NSData
然后通过base64 转换成 字符串 拼接到 body 中进行发送.(发送前将body前插入图片消息的标示)
.
语音:将录制好的NSData 语音数组,通过base64 转换成字符串.以下处理与图片消息一致,不在复述. 

同时 XMPP 提供了 2个消息 发送后的回调方法,分别是:
1.发送成功
- (void)xmppStream:(XMPPStream*)sender didSendMessage:(XMPPMessage*)message
2.发送失败
- (void)xmppStream:(XMPPStream*)sender
    didFailToSendMessage:(XMPPMessage*)message
                   error:(NSError*)error

由于时间较紧此次Demo并没有将消息发送成功和发送失败,以及消失超时进行处理.


6.添加好友
	添加好友需要用到的两个类分别是:
XMPPRoster	//这个类是管理好友,正删改查
XMPPRosterCoreDataStorage //提供用来管理Coredata进行好友存储的类
好友添加流程:
	首先检索输入的联系人是否是好友,如果不是 -> 发送添加好友请求(XMPPRoster调用 subscribePresenceToUser:Jid 此方法只是发送好友请求,不做其他任何操作) -> 等待被添加用户进行确认(xmpp可以设置默认同意) ->
根据被添加用户的操作状态回调,进行(添加好友,和删除好友,如果对方同意那么将用户添加到自己的好友列表当中,如果不同意那么将用户从自己的好友列表当中删除,这里需要解释一下为什么删除,为什么coredata存储好友信息,它使无论对方是否同意关注你,都会讲你发送过请求的用户信息添加到数据库当中当然服务器数据库也是这样的,所以对方拒绝添加的时候我选着了从好友列表当中删除) -> 当双方成为好友时更新好友列表(- (void)xmppRoster:(XMPPRoster*)sender
didReceiveRosterItem:(NSXMLElement*)item 回调方法)

8.消息列表
	XMPP自带消息存储(CoreData)所以此Demo并没有再通过数据库将消息做持久化的必要.一下只列出 过滤 所需要德联系人得消息记录,
通过谓词检索过滤出 当前回话联系人得消息记录
"streamBareJidStr == %@ AND bareJidStr == %@”
第一个为myJid,第二个为联系人Jid.
返回消息载体为XMPPMessageArchiving_Message_CoreDataObject 对象
这里有必要 介绍 该对象 的isOutgoing 属性,此属性是标示 消息来源,也就是说 代表是别人发给你的,还是你发给别人得 (YES 是你自己发的,NO…)

9.好友列表获取
好友列表可以通过两种方式得到
1.	通过 检索 本地数据库 获得好友列表 (此Demo采用了本方法).
2.	通过 向服务器发送请求 (此Demo讲此段代码注掉了,然而我发送的请求服务器并没有回答我,所以将此方法废弃).
下面是2中方式的代码 实现
 实体名 @” XMPPUserCoreDataStorageObject”
当然CoreData是支持排序的.我选着按 用户的Jid 进行了升序排序
@”jidStr”
返回的对象XMPPUserCoreDataStorageObject.


	由于本人技术和时间等因素,并未能将所有功能一一实现.
聊天室 和 用户 vCard 信息. Xmpp提供了实现方法.
	本人调研了 文件传输,语音通话,视频通话,所用到的 XEP 167,180, 176.协议,在网上的 所有xmppframework 当中 并没有找到.只是对相关实现原理进行了简单了解.

