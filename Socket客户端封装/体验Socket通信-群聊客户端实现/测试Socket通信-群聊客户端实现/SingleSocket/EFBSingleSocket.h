//
//  YPSingleSocket.h
//  体验Socket通信-群聊客户端实现
//
//  Created by navchina on 2017/8/9.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//
/*
 封装：1.给外界暴露一个连接服务器的借口
      2.断开连接
      3.发送数据
 */

#import <Foundation/Foundation.h>
#import "EFBSingleSocketProtocol.h"
typedef NS_ENUM(NSUInteger,SocketState){

    SocketState_Unlink = 0,
    SocketState_Linking = 1,
    SocketState_Linked = 2,
    SocketState_Logout = 3 //用户主动cut是不需要重连的
};

@interface EFBSingleSocket : NSObject

//创建单列
+(instancetype)shareSocket;

//连接服务器
-(void)connectSocketHost;

//断开连接
-(void)disConnectSocketHost;

@property (nonatomic, assign) SocketState socketState;


//模块类对象
@property (nonatomic, strong) id<EFBSingleSocketProtocol> moduleClass;

@property (nonatomic, strong) NSString *deviceToken;

@end
