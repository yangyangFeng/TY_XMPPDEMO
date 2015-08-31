//
//  MessageModel.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/19.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "MessageModel.h"

@implementation MessageModel

+ (id)messageWithText:(NSString*)text Image:(UIImage*)image Voice:(NSData*)voice andSecond:(NSInteger)second
{
    MessageModel* model = [[MessageModel alloc] init];
    model.second = second;
    if (text) {
        model.text = text;
    }
    if (image) {
        model.image = image;
    }
    if (voice) {
        model.voice = voice;
    }
    model.messageNumber = 0;
    return model;
}

- (NSInteger)messageType
{
    if (_text) {
        return 0; //文本类型
    }
    else if (_image) {
        return 1; //图片类型
    }
    else {
        return 2; //语音类型
    }
}

@end
