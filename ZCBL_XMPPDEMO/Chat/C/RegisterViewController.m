//
//  RegisterViewController.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/15.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "RegisterViewController.h"

@interface RegisterViewController ()
@property (weak, nonatomic) IBOutlet UITextField* filedID;
@property (weak, nonatomic) IBOutlet UITextField* filedPassword;
@property (nonatomic, strong) UITextField* field;
@end

@implementation RegisterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)resgisterDidClick:(id)sender
{
    if (_filedID.text.length && _filedID.text.length) {

        [[XMPPManager defaultManager] registerWithUserName:_filedID.text
                                                  password:_filedPassword.text
                                             WithCallblock:^(BOOL isSuccessed) {
                                                 if (isSuccessed) {
                                                     DLog(@"注册成功");
                                                 }
                                                 else {
                                                     DLog(@"注册失败");
                                                 }
                                             }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
    //    {
    //        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    //        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    //    }
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
