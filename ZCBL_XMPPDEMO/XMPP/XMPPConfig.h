//
//  XMPPConfig.h
//  XMPPSample
//
//  Created by lewis on 14-3-27.
//  Copyright (c) 2014年 com.lanou3g. All rights reserved.
//

#ifndef XMPPSample_XMPPConfig_h
#define XMPPSample_XMPPConfig_h

//openfire服务器IP地址192.168.0.124
#define  kHostName     [USER_DEFAULT objectForKey:@"kHostName"]
//openfire服务器端口 默认5222
#define  kHostPort          [[USER_DEFAULT objectForKey:@"kHostPort"] intValue]
//openfire 用户名
#define kDomin     [USER_DEFAULT objectForKey:@"kDomin"]

//resource
#define kResource     [USER_DEFAULT objectForKey:@"kResource"]

#define kNewMessageNotification @"ReceiveMessageNotification"
#endif
