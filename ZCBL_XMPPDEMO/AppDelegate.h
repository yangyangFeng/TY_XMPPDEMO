//
//  AppDelegate.h
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/15.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "XMPPFramework.h"
#import "BaseNavigationViewController.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate,XMPPStreamDelegate>

@property (strong, nonatomic) UIWindow* window;

//@property (strong, nonatomic) XMPPStream* xmppStream;
//@property (readonly, strong, nonatomic) NSManagedObjectContext* managedObjectContext;
//@property (readonly, strong, nonatomic) NSManagedObjectModel* managedObjectModel;
//@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, strong) BaseNavigationViewController * nav;
//
//+ (instancetype)sharedDelegate;
//- (void)saveContext;
//- (NSURL*)applicationDocumentsDirectory;
//
///*!
// *  是否连接
// */
//- (BOOL)connect;
//
///*!
// *  断开连接
// */
//- (void)disconnect;
//
///*!
// *  设置XMPPStream
// */
//- (void)setupStream;
//
///*!
// *  上线
// */
//- (void)goOnline;
//
//- (void)goOffline;

- (UIViewController *)currentController;
@end
