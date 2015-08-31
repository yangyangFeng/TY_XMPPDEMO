//
//  RootViewController.m
//  UUChatTableView
//
//  Created by shake on 15/1/4.
//  Copyright (c) 2015年 uyiuyao. All rights reserved.
//

#import "RootViewController.h"
#import "UUInputFunctionView.h"
#import "MJRefresh.h"
#import "UUMessageCell.h"
#import "ChatModel.h"
#import "UUMessageFrame.h"
#import "UUMessage.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#define historyNumbers 10
@interface RootViewController () <UUInputFunctionViewDelegate, UUMessageCellDelegate, UITableViewDataSource, UITableViewDelegate, XMPPManagerDelegate>

@property (strong, nonatomic) MJRefreshHeaderView* head;
@property (strong, nonatomic) ChatModel* chatModel;
@property (weak, nonatomic) IBOutlet UITableView* chatTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@property (nonatomic, strong) NSMutableArray* historyMessages;
@property (nonatomic, assign) NSInteger page;
@end

@implementation RootViewController {
    UUInputFunctionView* IFView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //    解决手势滑动与button事件冲突
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    self.title = _friendJID.user;
    
    self.page = 2;
    [self initBar];
    [self addRefreshViews];
    [self loadBaseViewsAndData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XMPPManager defaultManager].delegate = self;
    //add notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewScrollToBottom) name:UIKeyboardDidShowNotification object:nil];
    
    __weak RootViewController* weakself = self;
    [[XMPPManager defaultManager] fetchMessageListWithXMPPJID:_friendJID
                                                   Completion:^(NSArray* buddyList, NSString* errogMsg) {
                                                       [weakself.historyMessages addObjectsFromArray:buddyList];
                                                       
                                                       if (buddyList.count > historyNumbers) {
                                                           for (XMPPMessageArchiving_Message_CoreDataObject* message in [buddyList subarrayWithRange:NSMakeRange(buddyList.count - historyNumbers, historyNumbers)]) {
                                                               [weakself historyLoadingWith:message Refresh:NO];
                                                           }
                                                       }
                                                       else {
                                                           for (XMPPMessageArchiving_Message_CoreDataObject* message in buddyList) {
                                                               [weakself historyLoadingWith:message Refresh:NO];
                                                           }
                                                       }
                                                       
                                                   }];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [XMPPManager defaultManager].delegate = nil;
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}
- (void)dealloc
{
    self.navigationController.navigationBarHidden = YES;
}
- (void)initBar
{
    //    UISegmentedControl *segment = [[UISegmentedControl alloc]initWithItems:@[@" private ",@" group "]];
    //    [segment addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    //    segment.selectedSegmentIndex = 0;
    //    self.navigationItem.titleView = segment;
    
    self.navigationController.navigationBar.tintColor = [UIColor grayColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"好友列表" style:UIBarButtonItemStylePlain target:self action:@selector(popDidClick)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:nil];
}

- (void)popDidClick
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)segmentChanged:(UISegmentedControl*)segment
{
    self.chatModel.isGroupChat = segment.selectedSegmentIndex;
    [self.chatModel.dataSource removeAllObjects];
    [self.chatTableView reloadData];
}
#pragma mark - 下拉加载
- (void)addRefreshViews
{
    __weak typeof(self) weakSelf = self;
    
    _head = [MJRefreshHeaderView header];
    _head.scrollView = self.chatTableView;
    // 每次 默认刷新 10条数据
    _head.beginRefreshingBlock = ^(MJRefreshBaseView* refreshView) {
        NSInteger messageLength = historyNumbers;
        NSInteger messagelocation = weakSelf.page * historyNumbers;
        if (weakSelf.historyMessages.count >= messagelocation) {
            if (messagelocation + messageLength > weakSelf.historyMessages.count) {
                messageLength = weakSelf.historyMessages.count - messagelocation;
            }
            
            NSArray* tempMessage = [weakSelf.historyMessages subarrayWithRange:NSMakeRange(weakSelf.historyMessages.count - messagelocation, messageLength)];
            for (int i = 0; i < tempMessage.count; i++) {
                [weakSelf historyLoadingWith:tempMessage[tempMessage.count - 1 - i] Refresh:YES];
            }
            
            //        if (weakSelf.chatModel.dataSource.count > historyNumbers - 1) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:messageLength inSection:0];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.chatTableView reloadData];
                [weakSelf.chatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            });
            //        }
            weakSelf.page++;
        }
        [weakSelf.head endRefreshing];
    };
}
- (void)loadBaseViewsAndData
{
    self.chatModel = [[ChatModel alloc] init];
    self.chatModel.isGroupChat = NO;
    
    IFView = [[UUInputFunctionView alloc] initWithSuperVC:self];
    IFView.delegate = self;
    [self.view addSubview:IFView];
    
    [self.chatTableView reloadData];
    [self tableViewScrollToBottom];
}

- (void)keyboardChange:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    //adjust ChatTableView's height
    if (notification.name == UIKeyboardWillShowNotification) {
        self.bottomConstraint.constant = keyboardEndFrame.size.height + 40;
    }
    else {
        self.bottomConstraint.constant = 40;
    }
    
    [self.view layoutIfNeeded];
    
    //adjust UUInputFunctionView's originPoint
    CGRect newFrame = IFView.frame;
    newFrame.origin.y = keyboardEndFrame.origin.y - newFrame.size.height;
    IFView.frame = newFrame;
    
    [UIView commitAnimations];
}

//tableView Scroll to bottom
- (void)tableViewScrollToBottom
{
    if (self.chatModel.dataSource.count == 0)
        return;
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.chatModel.dataSource.count - 1 inSection:0];
    [self.chatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - InputFunctionViewDelegate
- (void)UUInputFunctionView:(UUInputFunctionView*)funcView sendMessage:(NSString*)message
{
    NSDictionary* dic = @{ @"strContent" : message,
                           @"type" : @(UUMessageTypeText),
                           @"from" : @(UUMessageFromMe),
                           @"userName" : [XMPPManager defaultManager].xmppStream.myJID.user };
    //发送 消息
    [[XMPPManager defaultManager] sendMessage:[MessageModel messageWithText:message Image:nil Voice:nil andSecond:0]
                                        toJID:_friendJID
                                WithCallblock:^(BOOL isSuccessed){
                                    
                                }];
    
    funcView.TextViewInput.text = @"";
    [funcView changeSendBtnWithPhoto:YES];
    [self dealTheFunctionData:dic Refresh:NO];
}

- (void)UUInputFunctionView:(UUInputFunctionView*)funcView sendPicture:(UIImage*)image
{
    
    [[XMPPManager defaultManager] sendMessage:[MessageModel messageWithText:nil Image:image Voice:nil andSecond:0]
                                        toJID:_friendJID
                                WithCallblock:^(BOOL isSuccessed){
                                    
                                }];
    
    NSDictionary* dic = @{ @"picture" : image,
                           @"type" : @(UUMessageTypePicture),
                           @"from" : @(UUMessageFromMe)
                           };
    [self dealTheFunctionData:dic Refresh:NO];
}

- (void)UUInputFunctionView:(UUInputFunctionView*)funcView sendVoice:(NSData*)voice time:(NSInteger)second
{
    
    [[XMPPManager defaultManager] sendMessage:[MessageModel messageWithText:nil Image:nil Voice:voice andSecond:second]
                                        toJID:_friendJID
                                WithCallblock:^(BOOL isSuccessed){
                                    
                                }];
    
    NSDictionary* dic = @{ @"voice" : voice,
                           @"strVoiceTime" : [NSString stringWithFormat:@"%d", (int)second],
                           @"type" : @(UUMessageTypeVoice),
                           @"from" : @(UUMessageFromMe) };
    [self dealTheFunctionData:dic Refresh:NO];
}

- (void)dealTheFunctionData:(NSDictionary*)dic Refresh:(BOOL)refresh
{
    if (refresh) {
        [self.chatModel insertSpecifiedItem:dic];
    }
    else {
        [self.chatModel addSpecifiedItem:dic];
    }
    //    [self.chatTableView reloadData];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.chatModel.dataSource.count - 1 inSection:0];
    
    [self.chatTableView beginUpdates];
    
    [self.chatTableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
    
    [self.chatTableView endUpdates];
    
    [self tableViewScrollToBottom];
}

#pragma mark - tableView delegate & datasource
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chatModel.dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UUMessageCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    if (cell == nil) {
        cell = [[UUMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID"];
        cell.delegate = self;
    }
    [cell setMessageFrame:self.chatModel.dataSource[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return [self.chatModel.dataSource[indexPath.row] cellHeight];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self.view endEditing:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark----- cellDelegate
- (void)headImageDidClick:(UUMessageCell*)cell userId:(NSString*)userId
{
    // headIamgeIcon is clicked
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:cell.messageFrame.message.userName message:@"headImage clicked" delegate:nil cancelButtonTitle:@"sure" otherButtonTitles:nil];
    [alert show];
}
//#pragma mark-----发送消息 XMPP
//- (void)sendMessageText:(NSString*)text
//{
//
//    [[XMPPManager defaultManager]sendMessage:text  toJID:_friendJID];
//}
//
//#pragma mark-----发送图片 XMPP
//- (void)sendImage:(NSString*)base64String withName:(NSString*)ImageName
//{
//    //将图片 信息herder 加上@"image" 作为语音i的表示
//    NSMutableString* imageString = [[NSMutableString alloc] initWithString:kImage];
//    [imageString appendString:base64String];
//    [[XMPPManager defaultManager]sendMessage:imageString toJID:_friendJID];
//}
//
//#pragma mark-----发送语音 XMPP
//- (void)sendAudio:(NSString*)base64String withName:(NSString*)audioName
//{
//    //将语音 信息herder 加上@"base64" 作为语音i的表示
//    NSMutableString* soundString = [[NSMutableString alloc] initWithString:kVoice];
//    [soundString appendString:base64String];
//    [[XMPPManager defaultManager]sendMessage:soundString toJID:_friendJID];
//}

#pragma mark----- 收到好友消息 XMPP
//- (void)xmppStream:(XMPPStream*)sender didReceiveMessage:(XMPPMessage*)message
//{
//    NSDictionary* dic = [NSDictionary dictionary];
//
//    if ([message.body hasPrefix:@"base64"]) {
//        //这是语音消息
//        NSData* audioData = [[message.body substringFromIndex:6] base64DecodedData];
//
//        DLog(@"收到好友语音消息");
//        dic = @{ @"voice" : audioData,
//            @"strVoiceTime" : [NSString stringWithFormat:@"%d", (int)5],
//            @"type" : @(UUMessageTypeVoice),
//            @"from" : @(UUMessageFromOther) };
//    }
//    else if ([message.body hasPrefix:@"image"]) {
//        NSData* imageData = [[message.body substringFromIndex:5] base64DecodedData];
//        UIImage* image = [UIImage imageWithData:imageData];
//        dic = @{ @"picture" : image,
//            @"type" : @(UUMessageTypePicture),
//            @"from" : @(UUMessageFromOther)
//        };
//    }
//    else {
//        NSLog(@"body=%@---type = %@", message.body, message.type);
//        // 文本消息
//        dic = @{ @"strContent" : message.body,
//            @"type" : @(UUMessageTypeText),
//            @"from" : @(UUMessageFromOther),
//            @"userName" : _friendJID.user };
//    }
//
//    [self dealTheFunctionData:dic];
//}

- (void)receivesMessage:(MessageModel*)message WithFromUserJID:(XMPPJID*)Jid MessageType:(ReceiveMessageType)type
{
    NSDictionary* dic = [NSDictionary dictionary];
    
    switch (message.messageType) {
        case ReceiveMessageText: {
            NSLog(@"body=%@---type = %ld", message.text, message.messageType);
            // 文本消息
            dic = @{ @"strContent" : message.text,
                     @"type" : @(UUMessageTypeText),
                     @"from" : @(UUMessageFromOther),
                     @"userName" : _friendJID.user };
        } break;
        case ReceiveMessageImage: {
            dic = @{ @"picture" : message.image,
                     @"type" : @(UUMessageTypePicture),
                     @"from" : @(UUMessageFromOther)
                     };
        } break;
        case ReceiveMessageVoice: {
            //这是语音消息
            
            DLog(@"收到好友语音消息");
            dic = @{ @"voice" : message.voice,
                     @"strVoiceTime" : [NSString stringWithFormat:@"%ld", message.second],
                     @"type" : @(UUMessageTypeVoice),
                     @"from" : @(UUMessageFromOther) };
        } break;
        default:
            break;
    }
    
    [self dealTheFunctionData:dic Refresh:NO];
}

- (void)historyLoadingWith:(XMPPMessageArchiving_Message_CoreDataObject*)messageCorData Refresh:(BOOL)refresh
{
    NSDictionary* dic = [NSDictionary dictionary];
    
    MessageFrom from = UUMessageFromOther;
    XMPPJID* userId = [XMPPManager defaultManager].xmppStream.myJID;
    if (messageCorData.isOutgoing) {
        from = UUMessageFromMe;
    }
    else
    {
        userId = messageCorData.bareJid;
    }
    XMPPMessage* message = messageCorData.message;
    
    MessageModel* model = [[MessageModel alloc] init];
    if ([message.bodytype hasPrefix:kVoice]) {
        //这是语音消息
        model.voice = [message.body base64DecodedData];
        dic = @{ @"voice" : model.voice,
                 @"strVoiceTime" : [NSString stringWithFormat:@"%d", (int)[[[message.bodytype componentsSeparatedByString:@"&"] lastObject] intValue]],
                 @"type" : @(UUMessageTypeVoice),
                 @"from" : @(from),
                 @"userName" : userId.user };
    }
    else if ([message.bodytype hasPrefix:kImage]) {
        model.image = [UIImage imageWithData:[message.body base64DecodedData]];
        
        dic = @{ @"picture" : model.image,
                 @"type" : @(UUMessageTypePicture),
                 @"from" : @(from),
                 @"userName" : userId.user
                 };
    }
    else {
        model.text = message.body;
        // 文本消息
        dic = @{ @"strContent" : model.text,
                 @"type" : @(UUMessageTypeText),
                 @"from" : @(from),
                 @"userName" : userId.user };
    }
    
    [self dealTheFunctionData:dic Refresh:refresh];
}

- (NSMutableArray*)historyMessages
{
    if (!_historyMessages) {
        _historyMessages = [NSMutableArray array];
    }
    return _historyMessages;
}

@end
