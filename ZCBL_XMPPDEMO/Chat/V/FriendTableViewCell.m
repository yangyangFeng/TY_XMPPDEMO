//
//  FriendTableViewCell.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/17.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "FriendTableViewCell.h"


@interface FriendTableViewCell ()

@property (nonatomic,strong)UILabel * stateLabel;

@property (nonatomic,strong) UILabel * device;

@end

@implementation FriendTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.stateLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [self.stateLabel setTextColor:[UIColor blueColor]];
        
        self.device = [[UILabel alloc]initWithFrame:CGRectZero];
        [self.device setTextColor:[UIColor orangeColor]];

        [self.contentView addSubview:self.device];
        [self.contentView addSubview:self.stateLabel];
    }
    return self;
}

-(void)setJID:(XMPPJID *)JID
{
    if (JID) {
        if (JID) {
            self.device.text = JID.resource;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.stateLabel.frame = CGRectMake(self.frame.size.width - 70, 5, 50, 22);
    
    self.device.frame = CGRectMake(self.frame.size.width - 180, 5, 60,22);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
