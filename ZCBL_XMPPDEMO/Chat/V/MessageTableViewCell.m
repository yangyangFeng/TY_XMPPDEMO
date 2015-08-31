//
//  MessageTableViewCell.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/21.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "MessageTableViewCell.h"

@interface MessageTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *numMessages;
@property (weak, nonatomic) IBOutlet UILabel *message;

@property (weak, nonatomic) IBOutlet UILabel *userName;

@property (weak, nonatomic) IBOutlet UIImageView *userIcon;
@end
@implementation MessageTableViewCell


-(void)setModel:(MessageModel *)model
{
    _model = model;
    _userName.text = model.fromJid.user;
    switch (model.messageType) {
        case 0:  // 文字
        {
            _message.text = model.text;
        }
            break;
            case 1:
        {
            _message.text = @"[图片]";
        }
            break;
            case 2:
        {
            _message.text = @"[语音消息]";
        }
            break;
        default:
            break;
    }
    _numMessages.text = [NSString stringWithFormat:@"%ld",model.messageNumber];
    if (model.messageNumber == 0) {
        _numMessages.alpha = 0;
    }
    else{
        _numMessages.alpha = 1.0;
    }
}
- (void)awakeFromNib {
    // Initialization code
    _numMessages.layer.masksToBounds = YES;
    _numMessages.layer.cornerRadius = _numMessages.frame.size.width / 2.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
