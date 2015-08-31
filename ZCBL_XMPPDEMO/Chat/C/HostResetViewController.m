//
//  HostResetViewController.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/18.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "HostResetViewController.h"

@interface HostResetViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField* hostName;
@property (weak, nonatomic) IBOutlet UITextField* domain;
@property (weak, nonatomic) IBOutlet UITextField* hostPort;

@property (nonatomic, strong) UITextField* field;
@end

@implementation HostResetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setSubviews];
    // Do any additional setup after loading the view.
}

- (void)setSubviews
{
    _hostName.text = kHostName;
    _hostPort.text = [NSString stringWithFormat:@"%d",kHostPort] ;
    _domain.text = kDomin;
}
- (IBAction)confirmDidClick:(id)sender
{
    if (_hostPort.text.length && _hostPort.text.length && _domain.text.length) {
        [USER_DEFAULT setObject:_hostName.text forKey:@"kHostName"];
        [USER_DEFAULT setObject:_hostPort.text  forKey:@"kHostPort"];
        [USER_DEFAULT setObject:_domain.text forKey:@"kDomin"];
        
        [[XMPPManager defaultManager] connectToOpenfireWithCallblock:^(BOOL isSuccessed) {
            
        }];
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"修改成功" message:@"" delegate:self cancelButtonTitle:@"确认" otherButtonTitles: nil];
        [alert show];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"修改失败" message:@"服务器配置不能为空" delegate:self cancelButtonTitle:@"取消" otherButtonTitles: nil];
        [alert show];
        
    }
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
    _field.text = @"";
    return YES;
}

@end
