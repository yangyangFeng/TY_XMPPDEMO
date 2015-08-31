//
//  AppDelegate.m
//  ZCBL_XMPPDEMO
//
//  Created by 邴天宇 on 15/7/15.
//  Copyright (c) 2015年 邴天宇. All rights reserved.
//

#import "AppDelegate.h"
#import "BaseNavigationViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
 

    if ([[UIApplication sharedApplication]currentUserNotificationSettings].types!=UIUserNotificationTypeNone) {
        //            如果授权那么 不操作
    }else{
        //        否者进行注册通知授权
        [[UIApplication sharedApplication]registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound  categories:nil]];
    }
    
    _window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    
    [_window makeKeyAndVisible];
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    _nav = [storyboard instantiateViewControllerWithIdentifier:@"BaseNavigationViewController"];
    
    [_window setRootViewController:_nav];
    [self setHost];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication*)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
//    [self saveContext];
}

//#pragma mark - Core Data stack
//
//@synthesize managedObjectContext = _managedObjectContext;
//@synthesize managedObjectModel = _managedObjectModel;
//@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
//
//- (NSURL*)applicationDocumentsDirectory
//{
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "iOS.UI.------------.ZCBL_XMPPDEMO" in the application's documents directory.
//    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//}
//
//- (NSManagedObjectModel*)managedObjectModel
//{
//    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
//    if (_managedObjectModel != nil) {
//        return _managedObjectModel;
//    }
//    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"ZCBL_XMPPDEMO" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    return _managedObjectModel;
//}
//
//- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
//{
//    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
//    if (_persistentStoreCoordinator != nil) {
//        return _persistentStoreCoordinator;
//    }
//
//    // Create the coordinator and store
//
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSURL* storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ZCBL_XMPPDEMO.sqlite"];
//    NSError* error = nil;
//    NSString* failureReason = @"There was an error creating or loading the application's saved data.";
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
//        // Report any error we got.
//        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
//        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
//        dict[NSUnderlyingErrorKey] = error;
//        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
//        // Replace this with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
//
//    return _persistentStoreCoordinator;
//}
//
//- (NSManagedObjectContext*)managedObjectContext
//{
//    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
//    if (_managedObjectContext != nil) {
//        return _managedObjectContext;
//    }
//
//    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
//    if (!coordinator) {
//        return nil;
//    }
//    _managedObjectContext = [[NSManagedObjectContext alloc] init];
//    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
//    return _managedObjectContext;
//}
//
//#pragma mark - Core Data Saving support
//
//- (void)saveContext
//{
//    NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
//    if (managedObjectContext != nil) {
//        NSError* error = nil;
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
//            // Replace this implementation with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//}



- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    //点击提示框的打开
    application.applicationIconBadgeNumber = 0;
}


#pragma mark-------------- XMPPDelegate -----------------
//- (void)setupStream
//{
//    if (!self.xmppStream) {
//        self.xmppStream = [[XMPPStream alloc] init];
//        //设置服务器
//        [self.xmppStream setHostName:kHostName];
//        [self.xmppStream setHostPort:kHostPort];
//        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
//    }
//}
//
//- (void)goOnline
//{
//    //发送在线状态
//    XMPPPresence* presence = [XMPPPresence presence];
//    [[self xmppStream] sendElement:presence];
//}
//
//- (void)goOffline
//{
//    //发送下线状态
//    XMPPPresence* presence = [XMPPPresence presenceWithType:@"unavailable"];
//    [[self xmppStream] sendElement:presence];
//}
//
//- (BOOL)connect
//{
//    [self setupStream];
//    //从本地取得用户名，密码和服务器地址
//
//    NSString* userId = user_id;
//    NSString* pass = user_pw;
//
//
//
//    if (![self.xmppStream isDisconnected]) {
//        return YES;
//    }
//    if (userId == nil || pass == nil) {
//        return NO;
//    }
//    //设置用户
//    [self.xmppStream setMyJID:[XMPPJID jidWithUser:user_id domain:Domain resource:kResource]];
//    NSError * error;
//    [self.xmppStream connectWithTimeout:30 error:&error];
//    if (error) {
//        DLog(@"%@",error);
//    }
////        密码
////            password = pass;
////    //    连接服务器
////            NSError *error = nil;
////            if (![self.xmppStream connect:&error]) {
////                NSLog(@"cant connect %@", server);
////                return NO;
////            }
//
//    return YES;
//}
//
//- (void)disconnect
//{
//    [self goOffline];
//    [self.xmppStream disconnect];
//}
//
//
//- (void)xmppStreamDidConnect:(XMPPStream *)sender
//{
//    NSLog(@"连接成功 回调");
////    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
//    NSError *error = nil;
//    if (![self.xmppStream authenticateWithPassword:user_pw error:&error]) {
//        NSLog(@"Authenticate Error: %@", [[error userInfo] description]);
//


//}

- (void)setHost
{
    if (!kHostName) {
            [USER_DEFAULT setObject:@"192.168.0.124" forKey:@"kHostName"];
    }
    if (!kHostPort) {
            [USER_DEFAULT setObject:@"5222" forKey:@"kHostPort"];
    }
    if (!kDomin) {
            [USER_DEFAULT setObject:@"zxcvbnm" forKey:@"kDomin"];
    }
    if (!kResource) {
            [USER_DEFAULT setObject:[NSString stringWithFormat:@"%f",IOS_VERSION] forKey:@"kResource"];
    }

}

- (UIViewController *)currentController
{
    return [self.nav visibleViewController];
}

//返回对象实例
+ (instancetype)sharedDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}
@end

