//
//  FriendTableViewController.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/17.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "FriendTableViewController.h"
#import "FriendTableViewCell.h"
#import "RootViewController.h"
#import "AppDelegate.h"
@interface FriendTableViewController () <UITableViewDataSource, UITableViewDelegate, XMPPManagerDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* rosterJIDs;
@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;
@end

@implementation FriendTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setSubviews];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;
    [XMPPManager defaultManager].delegate = self;
    self.rosterJIDs = [XMPPManager defaultManager].userFriendList;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XMPPManager defaultManager].delegate = nil;
}
- (void)setSubviews
{
    [self.view addSubview:self.tableView];

    UIBarButtonItem* addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDidClick:)];
    UIBarButtonItem* refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshDidClick:)];
//    self.navigationItem.rightBarButtonItems = @[ addButtonItem, refreshButtonItem ];
//    [AppDelegate sharedDelegate].nav.navigationItem.rightBarButtonItems = @[ addButtonItem, refreshButtonItem ];
//    UIBarButtonItem* back = [[UIBarButtonItem alloc] init];
//    [AppDelegate sharedDelegate].nav.navigationItem.leftBarButtonItem = back;
    self.tabBarController.navigationController.navigationItem.rightBarButtonItems = @[ addButtonItem, refreshButtonItem ];
    // 查询数据
    [self.fetchedResultsController performFetch:NULL];
}
- (IBAction)addDidClick:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"输入好友昵称" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"添加", NULL];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.delegate = self;
    [alert show];
}
- (IBAction)refreshDidClick:(id)sender
{
    [[XMPPManager defaultManager] fetchFriendListWithCompletion:^(NSArray* buddyList, NSString* errogMsg) {
        if (buddyList.count) {
            [self.rosterJIDs removeAllObjects];
            for (XMPPUserCoreDataStorageObject* temp in buddyList) {
                [self.rosterJIDs addObject:temp.jid];
                NSLog(@"%@",temp.ask);
            }

            [_tableView reloadData];
        }
    }];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex

{

    //得到输入框

    UITextField* firld = [alertView textFieldAtIndex:0];

    if (buttonIndex == 1) {

        if (firld.text.length) {
            [[XMPPManager defaultManager] addFriendWithXMPPJID:[XMPPJID jidWithUser:firld.text domain:kDomin resource:kResource]
                                                 WithCallblock:^(BOOL isSuccessed){

                                                 }];
        }
    }
}

- (void)receivesFriendList:(NSMutableArray*)friendList
{
    self.rosterJIDs = friendList;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return self.rosterJIDs.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* identifiter = @"FriendTableViewCell";
    FriendTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifiter];
    if (!cell) {
        cell = [[FriendTableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault)reuseIdentifier:identifiter];
    }

    XMPPJID* jid = [self.rosterJIDs objectAtIndex:indexPath.row];
    cell.textLabel.text = jid.user;
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RootViewController* private = [[RootViewController alloc] init];
private
    .friendJID = self.rosterJIDs[indexPath.row];
    [self.navigationController pushViewController:private animated:YES];

    MessageModel* userModel = [MessageModel messageWithText:@"" Image:nil Voice:nil andSecond:0];
    userModel.fromJid = [private.friendJID copy];
    if (![XMPPManager defaultManager].userMessageList.count) {
        [[XMPPManager defaultManager].userMessageList addObject:userModel];
        return;
    }
    BOOL state = NO;
    for (MessageModel* userMessageModel in [XMPPManager defaultManager].userMessageList) {
        if ([userModel.fromJid isEqualToJID:userMessageModel.fromJid]) {
            return;
        }
        state = YES;
    }
    if (state) {
        [[XMPPManager defaultManager].userMessageList addObject:userModel];
    }

    //    [[XMPPManager defaultManager] removeXMppUserXMPPJID:self.rosterJIDs[indexPath.row] WithCallblock:^(BOOL isSuccessed) {
    //
    //    }];

    // 查询卡片
    //    XMPPIQ *iq = [XMPPIQ iqWithType:@"get"];
    //    [iq addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@",private.friendJID]/*好友的jid*/];
    //    NSXMLElement *vElement = [NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"];
    //    [iq addChild:vElement];
    ////    通过xmppStream发送请求，重新下载vcard：
    //    [[XMPPManager defaultManager].xmppStream sendElement:iq];

    //    [[XMPPManager defaultManager].xmppvCardTempModule fetchvCardTempForJID:private.friendJID];
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    // 指定查询的实体
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];

    // 在线状态排序
    NSSortDescriptor* sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sectionNum" ascending:YES];
    // 显示的名称排序
    NSSortDescriptor* sort2 = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];

    // 添加排序
    request.sortDescriptors = @[ sort1, sort2 ];

    // 添加谓词过滤器
    request.predicate = [NSPredicate predicateWithFormat:@"!(subscription CONTAINS 'none')"];

    // 添加上下文
    NSManagedObjectContext* ctx = [XMPPManager defaultManager].xmppRosterStorage.mainThreadManagedObjectContext;

    // 实例化结果控制器
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:ctx sectionNameKeyPath:nil cacheName:nil];

    // 设置他的代理
    _fetchedResultsController.delegate = self;

    return _fetchedResultsController;
}
- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    NSLog(@"上下文改变");
    [self.tableView reloadData];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UITableViewCell* cell = (UITableViewCell*)sender;
    //    ChatViewController *chatVC = segue.destinationViewController;
    //    NSIndexPath *indexPath=[self.tableView indexPathForCell:cell];
    //    XMPPJID *jid=[self.rosterJIDs objectAtIndex:indexPath.row];
    //    chatVC.chatToJid = jid;
}

- (UITableView*)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64) style:(UITableViewStylePlain)];

        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray*)rosterJIDs
{
    if (!_rosterJIDs) {
        _rosterJIDs = [NSMutableArray arrayWithCapacity:0];
    }
    return _rosterJIDs;
}
@end
