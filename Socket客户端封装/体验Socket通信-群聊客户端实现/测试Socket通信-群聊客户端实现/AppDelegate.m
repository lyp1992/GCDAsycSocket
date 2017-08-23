//
//  AppDelegate.m
//  测试Socket通信-群聊客户端实现
//
//  Created by 赖永鹏 on 2017/8/8.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import "AppDelegate.h"

#import "EFBSingleSocketProtocol.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    UIWindow *win = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController *vc =  [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ViewController"];
    win.rootViewController = vc;
   
    self.singleSocket = [EFBSingleSocket shareSocket];
    
    [win makeKeyAndVisible];
    
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{

    self.singleSocket.deviceToken = deviceToken;
    NSLog(@"%@",deviceToken);
}

- (void)applicationWillResignActive:(UIApplication *)application {

}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
   
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {

    
}


- (void)applicationWillTerminate:(UIApplication *)application {
   
}


@end
