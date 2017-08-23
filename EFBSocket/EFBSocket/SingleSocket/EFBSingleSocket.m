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
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "NSMutableDictionary+EFBNullSaf.h"

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

-(void)registerModuleClass:(id<EFBSingleSocketProtocol>)moduleClass withHostUrl:(NSString *)hostUrl withPort:(UInt32)port withPilotID:(NSString *)PilotID withDeviceToken:(NSString *)deviceToken{

    if (![self.moduleArr containsObject:moduleClass]) {
        [self.moduleArr addObject:moduleClass];
    }
    self.hostUrl = hostUrl;
    self.port = port;
    self.PilotID = PilotID;
    self.deviceToken = deviceToken;
    
    if (self.moduleArr.count == 1) {
        //只有第一次的时候连接服务器
        [self connectSocketHost];
    }
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
    NSString *host = [self getProperIPWithAddress:self.hostUrl port:self.port];
    [self.clientSocket connectToHost:host onPort:self.port error:&error];

    if (error) {
        
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
    [self.reConnecttimer invalidate];
}

-(void)reConnectSocket{
   
    if (self.socketState != SocketState_Linked && self.socketState != SocketState_Logout) {

        [self connectSocketHost];
    }else{
        //关闭

        [self.reConnecttimer invalidate];
        
    }
}

-(void)connectServerAndSendMessaegWithReceivedSuccess:(BOOL)success{
    //获取时间
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *dateF = [[NSDateFormatter alloc]init];
    dateF.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [dateF stringFromDate:date];

    NSString *uuidString = [self getUUID_UDID];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:uuidString forKey:@"UDID"];
    [dic setObject:self.deviceToken forKey:@"devicetoken"];
    [dic setObject:self.PilotID forKey:@"PilotID"];
    [dic setValue:@(success) forKey:@"clientReceived"];
    [dic setObject:dateStr forKey:@"timeStamp"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [self.clientSocket writeData:data withTimeout:3 tag:KSocketTag];
}

#pragma mark --GCDAsyncSocketDelegate
//连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"连接成功");
    //连接成功之后给后台发送devicetoken,UUID,员工号
    [self connectServerAndSendMessaegWithReceivedSuccess:NO];
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
    [self connectServerAndSendMessaegWithReceivedSuccess:YES];
    
    [self.clientSocket readDataWithTimeout:-1 tag:KSocketTag];
    
}

//发送成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}

//断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"与服务器断开连接：%@", err);
    if ((err && [[err localizedDescription] isEqualToString:@"Network is unreachable"])||self.socketState == SocketState_Logout) {//断网了就不用再走这个定时器了
        [self disConnectSocketHost];
        return;
    }
    self.socketState = SocketState_Unlink;
    if (!self.reConnecttimer.isValid) {
        //开启一个定时器，重连服务器
        self.reConnecttimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(reConnectSocket) userInfo:nil repeats:YES];
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
//                [self disConnectSocketHost];
//                //                //重连服务器
//                if (self.socketState == SocketState_Unlink) {
//                    [self reConnectSocket];
//                }
            }
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                //先断开之前的，
//                [self disConnectSocketHost];
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

//整个程序获取到UDID或者UUID
-(NSString *)getUUID_UDID{
    NSString * deviceCode;
    
    //沙盒里面有一个存储UDID的文件(TXT)
    NSString *path=[[self getDataPath] stringByAppendingPathComponent:@"UDIDCode.txt"];
    NSString* Doc_UDID = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (Doc_UDID.length > 0) {
        deviceCode = Doc_UDID;
    }
    
    if (deviceCode.length == 0) {
        deviceCode = @"";
    }
    
    return deviceCode;
    
}
-(NSString *)getDataPath
{
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
   NSString *docPath= [documentPaths objectAtIndex:0];
    
    return docPath;
    
}
@end
