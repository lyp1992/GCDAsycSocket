//
//  ViewController.h
//  测试Socket通信-群聊客户端实现
//
//  Created by 赖永鹏 on 2017/8/8.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,SocketState){
    SocketState_UNLINK   = 0, // 未连接
    SocketState_LINKING  = 1, // 连接中
    SocketState_LINKED   = 2, // 连接成功了
    SocketState_LOGOUT   = 3 // 退出登录(退出软件用户时的情况，不需要重连)
};

@interface ViewController : UIViewController

@property (nonatomic, assign) SocketState socketState;

@end

