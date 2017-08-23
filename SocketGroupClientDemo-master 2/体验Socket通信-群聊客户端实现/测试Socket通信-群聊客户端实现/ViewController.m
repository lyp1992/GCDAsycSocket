//
//  ViewController.m
//  测试Socket通信-群聊客户端实现
//
//  Created by 赖永鹏 on 2017/8/8.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "RealReachability.h"

#define KHostUrl @"192.168.125.100"
#define KPort 50000
@interface ViewController ()<UITableViewDataSource, GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, strong) NSMutableArray *dataArr;

@property (nonatomic, strong) NSTimer *connectTimer; // 计时器

@property (nonatomic, strong)  NSTimer *reConnecttimer;

@property (nonatomic, assign) int beatCount;

@property (nonatomic, assign) BOOL isSenderMessage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 实现聊天室
    [self socketConnectHost];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(networkChanged:) name:kRealReachabilityChangedNotification object:nil];
}

-(void)socketConnectHost{
        // 1. 连接到服务器
        NSError *error = nil;
    //适配ipV6
    NSString *host = [self getProperIPWithAddress:KHostUrl port:KPort];
    NSLog(@"host==%@",host);
    [self.clientSocket connectToHost:host onPort:KPort error:&error];
        self.socketState = SocketState_LINKING;
        if (error) {
            NSLog(@"error:%@", error);
            self.socketState = SocketState_UNLINK;
        }else{
            self.socketState = SocketState_LINKED;
        }
}

-(void)longConnectToSocket{

    // 根据服务器要求发送固定格式的数据，假设为指令@"longConnect"，但是一般不会是这么简单的指令
    
    NSString *longConnect = @"longConnect";
    
    NSData *dataStream = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.clientSocket writeData:dataStream withTimeout:-1 tag:1];
}
//断开服务器连接
-(void)disConectHost{

    [self.clientSocket disconnect];
    self.socketState = SocketState_UNLINK;
    [self.reConnecttimer invalidate];
    [self.connectTimer invalidate];
}

-(void)reConnectSocket{
    if (self.socketState != SocketState_LINKED) {
//        self.beatCount++;
        [self socketConnectHost];
    }else{
    //关闭
//        self.beatCount = 0;
        [self.reConnecttimer invalidate];
        [self.connectTimer invalidate];
    }
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)clientSock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"与服务器连接成功！");
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"idfv==%@",idfv);
    //连接上之后给服务器发消息
      [self.clientSocket writeData:[idfv dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:0];
    // 监听读取数据（在读数据的时候，要监听有没有数据可读，目的是保证数据读取到）
    self.socketState = SocketState_LINKED;
    [clientSock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.clientSocket disconnect];
    self.clientSocket = nil;
//    Connection refused
//    Undefined
//    Socket closed by remote peer
//    The operation couldn’t be completed. Socket is not connected
//    Network is unreachable
    NSLog(@"与服务器断开连接：%@", err);
    if (err && [[err localizedDescription] isEqualToString:@"Network is unreachable"]) {
    
        [self disConectHost];
        return;
    }
    self.socketState = SocketState_UNLINK;
    if (!self.reConnecttimer.isValid && ![[err localizedDescription] isEqualToString:@"Network is unreachable"]) {
        
        //开启一个定时器，重连服务器
        self.reConnecttimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(reConnectSocket) userInfo:nil repeats:YES];
        [self.reConnecttimer fire];
    }
}

// 读取数据(接收消息)
- (void)socket:(GCDAsyncSocket *)clientSock didReadData:(NSData *)data withTag:(long)tag {
    NSString *messageStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"接收到消息：%@", messageStr);
    messageStr = [NSString stringWithFormat:@"【匿名】：%@", messageStr];
    [self.dataArr addObject:messageStr];
    // 刷新UI要在主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    // 监听读取数据（读完数据后，继续监听有没有数据可读，目的是保证下一次数据可以读取到）
    [clientSock readDataWithTimeout:-1 tag:0];
}
//发送成功了之后
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    if (self.textField.text.length>0 && self.isSenderMessage) {
        NSLog(@"消息发送成功：%@",self.textField.text);
        NSString *senderStr = [NSString stringWithFormat:@"【我】：%@", self.textField.text];
        [self.dataArr addObject:senderStr];
        [self.tableView reloadData];
        [sock readDataWithTimeout:-1 tag:0];
        self.textField.text = nil;
        self.isSenderMessage = NO;
    }
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.dataArr[indexPath.row];
    return cell;
}

- (IBAction)clickSenderBtn:(UIButton *)sender {
    [self.view endEditing:YES];
    NSString *senderStr = self.textField.text;
    senderStr = [NSString stringWithFormat:@"%@",senderStr];
    if (senderStr.length == 0) {
        return;
    }
    self.isSenderMessage = YES;
    // 发送数据
    [self.clientSocket writeData:[senderStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:5 tag:0];
}

- (void)networkChanged:(NSNotification *)notification{

    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    if (status == RealStatusNotReachable) {
        //主动断开连接
        if (self.socketState == SocketState_LINKED) {
            NSLog(@"无网络");
            [self disConectHost];
        }
    }
    if (status == RealStatusViaWiFi) {
        
        //先断开之前的
        [self disConectHost];
        //重连服务器
        if (self.socketState == SocketState_UNLINK) {
            [self socketConnectHost];
            NSLog(@"有wifi");
        }
    }
    
    if (status == RealStatusViaWWAN) {
        
        WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
        switch (accessType) {
            case WWANType2G:
                NSLog(@"2G");
                break;
            case WWANType3G:
                NSLog(@"2G");
                break;
            case WWANType4G:
                NSLog(@"4G");
            {
                    //先断开之前的
                    [self disConectHost];
                    //重连服务器
                    if (self.socketState == SocketState_UNLINK) {
                        [self socketConnectHost];
                    }

            }
                break;
            default:
                NSLog(@"未知网络");
                break;
        }
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


- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clientSocket;
}

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc]init];
    }
    return _dataArr;
}

@end
