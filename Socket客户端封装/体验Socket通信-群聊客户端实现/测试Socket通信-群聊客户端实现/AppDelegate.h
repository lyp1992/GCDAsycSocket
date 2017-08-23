//
//  AppDelegate.h
//  测试Socket通信-群聊客户端实现
//
//  Created by 赖永鹏 on 2017/8/8.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EFBSingleSocket.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) EFBSingleSocket *singleSocket;
@end

