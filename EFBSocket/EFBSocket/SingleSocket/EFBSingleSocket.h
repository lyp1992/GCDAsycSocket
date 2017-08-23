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
//
//#define KHostUrl @"192.168.125.105"
//#define KPort 5488
#define KSocketTag 0

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

//模块类对象 ，
//写一个方法，注册对象。不要用属性
-(void)registerModuleClass:(id<EFBSingleSocketProtocol>)moduleClass withHostUrl:(NSString *)hostUrl withPort:(UInt32)port withPilotID:(NSString *)PilotID withDeviceToken:(NSString *)deviceToken;


//当前ipad的唯一表示
@property (nonatomic, copy) NSString *deviceToken;
//人员工号
@property (nonatomic, copy) NSString *PilotID;
//服务器地址
@property (nonatomic, copy) NSString *hostUrl;
//服务器端口
@property (nonatomic, assign) UInt32 port;

@end
