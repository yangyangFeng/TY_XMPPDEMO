//
//  LoginViewController.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/15.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "LoginViewController.h"
#import "ChatViewController.h"
#import "RegisterViewController.h"
#import "XMPPManager.h"
#import "FriendTableViewController.h"
#import "TabBarViewController.h"
#import "UUProgressHUD.h"
#import "MBProgressHUD.h"
@interface LoginViewController () <UITextFieldDelegate, XMPPStreamDelegate>
@property (weak, nonatomic) IBOutlet UITextField* fieldID;
@property (weak, nonatomic) IBOutlet UITextField* fieldPassword;
@property (nonatomic, strong) UITextField* field;
@property (nonatomic, strong) UIStoryboard* storyBoard;
@end

@implementation LoginViewController

- (UIStoryboard*)storyBoard
{
    if (!_storyBoard) {
        _storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    }
    return _storyBoard;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBar.tintColor = [UIColor grayColor];

    //    [[XMPPManager defaultManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    // Do any additional setup after loading the view.
}
#pragma mark - 登陆成功
- (IBAction)loginDidClock:(id)sender
{

    MBProgressHUD* progress = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progress];
    progress.labelText = @"登陆中";
    [progress show:YES];
    __weak typeof(self) weakSelf = self;
    [[XMPPManager defaultManager] loginWithUserName:_fieldID.text
                                           password:_fieldPassword.text
                                      WithCallblock:^(BOOL isSuccessed) {

                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                              [progress hide:YES];
                                              UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                              TabBarViewController* tabbar = [storyboard instantiateViewControllerWithIdentifier:@"TabBarViewController"];

                                              [weakSelf.navigationController pushViewController:tabbar animated:YES];
                                          });

                                      }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        progress.labelText = @"登陆失败";
        [progress hide:YES];
    });
}

#pragma mark - 注册
- (IBAction)registerDidClick:(id)sender
{

    RegisterViewController* registerController = [self.storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];

    [self.navigationController pushViewController:registerController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    if (_field) {
        [_field resignFirstResponder];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    _field = textField;
    return YES;
}
@end
