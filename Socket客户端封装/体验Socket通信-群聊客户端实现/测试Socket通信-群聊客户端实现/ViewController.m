//
//  ViewController.m
//  测试Socket通信-群聊客户端实现
//
//  Created by 赖永鹏 on 2017/8/8.
//  Copyright © 2017年 赖永鹏. All rights reserved.
//

#import "ViewController.h"
#import "EFBSingleSocket.h"

@interface ViewController ()<UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) NSMutableArray *dataArr;

@property (nonatomic, strong) EFBSingleSocket *singleSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.singleSocket = [EFBSingleSocket shareSocket];
    self.singleSocket.moduleClass = self;
  
}


-(void)EFB_socketDidReceiveData:(NSString *)socketString{

    NSString *str = [NSString stringWithFormat:@"匿名：%@",socketString];
    NSLog(@"str==%@",str);
    [self.dataArr addObject:str];
    [self.tableView reloadData];
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

#pragma mark --YPSingleSocketDelegate
-(void)socketDidReadData:(NSData *)data{

    NSString *readStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSString *str = [NSString stringWithFormat:@"匿名：%@",readStr];
    [self.dataArr addObject:str];
    [self.tableView reloadData];
    
}

-(void)socketDidSendSuccess{
    
    NSString *senderStr = [NSString stringWithFormat:@"我:%@",self.textField.text];
    [self.dataArr addObject:senderStr];
    [self.tableView reloadData];
    self.textField.text = nil;
}

- (IBAction)clickSenderBtn:(UIButton *)sender {
//    NSLog(@"发送消息");
    [self.view endEditing:YES];
    NSString *senderStr = self.textField.text;
    if (senderStr.length == 0) {
        return;
    }
//    NSData *data = [senderStr dataUsingEncoding:NSUTF8StringEncoding];
  
}

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc]init];
    }
    return _dataArr;
}

@end
