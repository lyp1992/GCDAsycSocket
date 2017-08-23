//
//  MyService.m
//  测试Socket连接
//
//  Created by 赖永鹏 on 2017/8/8.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import "MyService.h"
#import "GCDAsyncSocket.h"

@interface MyService ()<GCDAsyncSocketDelegate>
/** 保存服务端的Socket对象 */
@property (nonatomic, strong) GCDAsyncSocket *serviceSocket;
/** 保存客户端的所有Socket对象 */
@property (nonatomic, strong) NSMutableArray *clientSocketArr;

@end

@implementation MyService

//开启10086服务:5288
- (void)startService {
    NSError *error = nil;
    // 绑定端口 + 开启监听
    [self.serviceSocket acceptOnPort:5688 error:&error];
    if (!error) {
        NSLog(@"服务开启成功！");
    } else {
        NSLog(@"服务开启失败！");
    }
}

#pragma mark -- 实现代理的方法 如果有客户端的Socket连接到服务器，就会调用这个方法。
- (void)socket:(GCDAsyncSocket *)serviceSocket didAcceptNewSocket:(GCDAsyncSocket *)clientSocket {
    // 客户端的端口号是系统分配的，服务端的端口号是我们自己分配的
    NSLog(@"客户端【Host:%@, Port:%d】已连接到服务器!", clientSocket.connectedHost, clientSocket.connectedPort);
    //1.保存客户端的Socket（客户端的Socket被释放了，连接就会关闭）
    [self.clientSocketArr addObject:clientSocket];
    
    //2.监听客户端有没有数据上传 (参数1：超时时间，-1代表不超时；参数2：标识作用，现在不用就写0)
    [clientSocket readDataWithTimeout:-1 tag:0];
}


#pragma mark -- 服务器端 读取 客户端请求（发送）的数据。在服务端接收客户端数据，这个方法会被调用
- (void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag {
    //1.获取客户端发送的数据
    NSString *messageStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到客户端【Host:%@, Port:%d】发送的数据:%@",  clientSocket.connectedHost, clientSocket.connectedPort, messageStr);
    // 遍历客户端数组
    for (GCDAsyncSocket *socket in self.clientSocketArr) {
        if (socket != clientSocket) { // 不转发给自己
            //2.服务端把收到的消息转发给其它客户端
            [socket writeData:data withTimeout:1 tag:0];
        }
//        else{
//            //如果是自己，服务器给客户端发一条消息，已收到
//            [socket writeData:[@"success" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
//        }
    }
    //由于框架内部的实现，每次读完数据后，都要调用一次监听数据的方法（保证能接收到客户端第二次上传的数据）
    [clientSocket readDataWithTimeout:-1 tag:0];
}


-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{

       NSLog(@"接收到客户端【Host:%@, Port:%d】断开连接",  sock.connectedHost, sock.connectedPort);
}

-(void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{

    NSLog(@"接收到客户端【Host:%@, Port:%d】关闭了消息发送",  sock.connectedHost, sock.connectedPort);
}

- (GCDAsyncSocket *)serviceSocket {
    if (!_serviceSocket) {
        // 1.创建一个Socket对象
        // serviceSocket 服务端的Socket只监听 有没有客户端请求连接
        // 队列：代理的方法在哪个队列里调用 (子线程的队列)
        _serviceSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return _serviceSocket;
}

- (NSMutableArray *)clientSocketArr {
    if (!_clientSocketArr) {
        _clientSocketArr = [[NSMutableArray alloc]init];
    }
    return _clientSocketArr;
}

@end
