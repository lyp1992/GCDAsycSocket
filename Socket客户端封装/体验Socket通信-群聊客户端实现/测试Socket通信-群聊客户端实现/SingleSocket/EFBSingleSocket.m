//
//  YPSingleSocket.m
//  体验Socket通信-群聊客户端实现
//
//  Created by navchina on 2017/8/9.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import "EFBSingleSocket.h"
#import "EFBGCDAsyncSocket.h"
#import "AFNetworking.h"

#define KHostUrl @"192.168.125.105"
#define KPort 5488
#define KSocketTag 0

@interface EFBSingleSocket ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, assign) int beatCount;

@property (nonatomic, assign) BOOL isSendMessage;

@property (nonatomic, strong) NSTimer *reConnecttimer;

//模块数组
@property (nonatomic, strong) NSMutableArray *moduleArr;

@end

@implementation EFBSingleSocket

+(instancetype)shareSocket{
    static EFBSingleSocket *sinleSocket;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sinleSocket = [[EFBSingleSocket alloc]init];
        
    });
    return sinleSocket;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.moduleArr = [NSMutableArray array];
    }
    return self;
}

-(void)setModuleClass:(id<EFBSingleSocketProtocol>)moduleClass{

    _moduleClass = moduleClass;
    if (![self.moduleArr containsObject:moduleClass]) {
        [self.moduleArr addObject:moduleClass];
    }
    
    if (self.moduleArr.count == 1) {
        //只有第一次的时候连接服务器
        [self connectSocketHost];
    }
}


-(void)setDeviceToken:(NSString *)deviceToken{
    _deviceToken = deviceToken;
}

-(GCDAsyncSocket *)clientSocket{

    if (!_clientSocket) {

        _clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clientSocket;
}

//连接服务器
-(void)connectSocketHost{

    NSError *error = nil;
    //适配ipV6
    NSString *host = [self getProperIPWithAddress:KHostUrl port:KPort];
    [self.clientSocket connectToHost:host onPort:KPort error:&error];
    if (error) {
        NSLog(@"error: %@",error);
        self.socketState = SocketState_Unlink;
    }else{
    
        self.socketState = SocketState_Linked;
    }
    //监测网络
    [self startMonitoringNetwork];
}

-(void)disConnectSocketHost{
    
    [self.clientSocket disconnect];
    self.socketState = SocketState_Unlink;
    self.beatCount = 0;
   
}

-(void)reConnectSocket{

    if (self.socketState != SocketState_Linked && self.beatCount < 11 && self.socketState != SocketState_Logout) {
        self.beatCount++;
        [self connectSocketHost];
    }else{
        //关闭
        self.beatCount = 0;
    
    }
}

-(void)sendMessage:(id)message{

    if ([message isKindOfClass:[NSData class]]) {
            [self.clientSocket writeData:message withTimeout:3 tag:KSocketTag];
    }else{
        NSData *dataStream = [message dataUsingEncoding:NSUTF8StringEncoding];
        [self.clientSocket writeData:dataStream withTimeout:3 tag:KSocketTag];
    }
}

#pragma mark --GCDAsyncSocketDelegate
//连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    //连接成功之后给后台发送devicetoken
    NSString *connectStr = [NSString stringWithFormat:@"%@\r\n",self.deviceToken];
    [self sendMessage:connectStr];
    
    // 监听读取数据（在读数据的时候，要监听有没有数据可读，目的是保证数据读取到）
    self.socketState = SocketState_Linked;
    [self.clientSocket readDataWithTimeout:-1 tag:KSocketTag];
  
}
//读取到数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    //1.解析data
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    //给模块类发送消息
    for (id<EFBSingleSocketProtocol> vc in self.moduleArr) {
        [vc EFB_socketDidReceiveData:text];
    }
    //给服务器发送消息
    NSString *recevieStr = @"客户端收到了消息\r\n";
    [self sendMessage:recevieStr];
    
    
     [self.clientSocket readDataWithTimeout:-1 tag:KSocketTag];

}

//发送成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}
//断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"与服务器断开连接：%@", err);
    self.socketState = SocketState_Unlink;
    if (!self.reConnecttimer.isValid) {
        //开启一个定时器，重连服务器
        self.reConnecttimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(reConnectSocket) userInfo:nil repeats:YES];
        [self.reConnecttimer fire];
    }
}

//针对ipv6网络环境下适配，ipv4环境直接使用原来的地址
- (NSString *)getProperIPWithAddress:(NSString *)ipAddr port:(UInt32)port
{
    NSError *addresseError = nil;
    NSArray *addresseArray = [GCDAsyncSocket lookupHost:ipAddr port:port error:&addresseError];
    if (addresseError) {
        NSLog(@"");
    }
    
    NSString *ipv6Addr = @"";
    for (NSData *addrData in addresseArray) {
        if ([GCDAsyncSocket isIPv6Address:addrData]) {
            ipv6Addr = [GCDAsyncSocket hostFromAddress:addrData];
        }
    }
    
    if (ipv6Addr.length == 0) {
        ipv6Addr = ipAddr;
    }
    return ipv6Addr;
}

- (void)startMonitoringNetwork {
    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    [networkManager startMonitoring];
    //    __weak __typeof(&*self) weakSelf = self;
    [networkManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
            {
                //主动断开连接
                    NSLog(@"无网络");
                    [self disConnectSocketHost];
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                NSLog(@"有热点");
            }
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
//                //重连服务器
                if (self.socketState == SocketState_Unlink) {
                    [self reConnectSocket];
                    NSLog(@"有wifi");
                }
                
            }
                break;
            default:
                break;
        }
    }];
}

@end
