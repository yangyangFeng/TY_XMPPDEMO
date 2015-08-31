//
//  MessageViewController.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/21.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "MessageViewController.h"
#import "XMPPFramework.h"
#import "MessageTableViewCell.h"
#import "RootViewController.h"
@interface MessageViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property (nonatomic, strong) NSMutableArray * messageFromJids;
@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    id sender;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessage:) name:kNewMessageNotification object:sender];
    // Do any additional setup after loading the view.
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [XMPPManager defaultManager].userMessageList.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MessageTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"MessageTableViewCell"];
    if (!cell) {
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        cell =(MessageTableViewCell*) [storyboard instantiateViewControllerWithIdentifier:@"MessageTableViewCell"];
    }
    cell.model = [XMPPManager defaultManager].userMessageList[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RootViewController * private = [[RootViewController alloc]init];
    MessageModel * model = [XMPPManager defaultManager].userMessageList[indexPath.row];
    model.messageNumber = 0;
    private.friendJID = model.fromJid;
    [tableView reloadData];
    [self.navigationController pushViewController:private animated:YES];
}


- (void)receiveMessage:(NSNotification *)notification
{
    MessageModel * model = notification.object;
   
    XMPPJID * Jid = [notification.userInfo objectForKey:@"Jid"];
    model.fromJid = Jid;
    
    for (MessageModel * tempModel in [XMPPManager defaultManager].userMessageList) {
        if ([tempModel.fromJid.user isEqualToString:Jid.user]) {
            tempModel.text = model.text;
            tempModel.image = model.image;
            tempModel.voice = model.voice;
            tempModel.messageNumber++;
            [self.tableview reloadData];
            return;
        }
    }
     model.messageNumber++;
    [[XMPPManager defaultManager].userMessageList addObject:model];
    [self.tableview reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
    self.navigationController.navigationBarHidden = YES;
    
    if (self.tableview) {
        [self.tableview reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMessageNotification object:nil];
}
-(NSMutableArray *)messageFromJids
{
    if (!_messageFromJids) {
        _messageFromJids = [NSMutableArray array];
    }
    return _messageFromJids;
}
@end
