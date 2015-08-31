//
//  MyViewController.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/21.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "MyViewController.h"
#import "MBProgressHUD.h"
@interface MyViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *userIcon;

@property (weak, nonatomic) IBOutlet UILabel *userName;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)logoutDIdClick:(id)sender {
    MBProgressHUD * hud = [[MBProgressHUD alloc]initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText = @"注销中";
    [hud show:YES];
    hud.dimBackground = YES;
    __weak  MyViewController * weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hide:YES];
        [[XMPPManager defaultManager] logout];
        [weakself.navigationController popToRootViewControllerAnimated:YES];
    });
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
