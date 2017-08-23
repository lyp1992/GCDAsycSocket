//
//  YPSingleSocketProtocol.h
//  体验Socket通信-群聊客户端实现
//
//  Created by navchina on 2017/8/14.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EFBSingleSocketProtocol

//后台定义类型
-(void)EFB_socketDidReceiveData:(NSString *)socketString;

@end
