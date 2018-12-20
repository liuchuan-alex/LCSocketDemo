//
//  ViewController.m
//  LCSocketClientDemo
//
//  Created by 刘川 on 2018/12/19.
//  Copyright © 2018 alex. All rights reserved.
//

#import "ViewController.h"
#import "TCPSocketClient.h"

@interface ViewController ()<TCPSocketClientDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
  
}

- (IBAction)contentServer:(id)sender {
    //  开启连接
    [[TCPSocketClient sharedSocket] connectServerWithDelegate:self ToHost:@"10.4.161.98" onPort:8888];
    
}

- (IBAction)sendData:(id)sender {
    //  发送文字到服务器
    if (self.textField.text.length > 0) {
        NSData *data =[self.textField.text dataUsingEncoding:NSUTF8StringEncoding];
        [[TCPSocketClient sharedSocket] sendData:data];
    }
}

#pragma -mark TCPSocketClientDelegate
/**
 读取数据
 */
- (void)socket:(TCPSocketClient *)socket didReadData:(NSData *) data{
    NSLog(@"%@",data);
}

/**
 监听连接状态变化
 */
- (void)socket:(TCPSocketClient *)socket SocketConnectStatus:(SocketConnectStatus) connectStatus{
    NSLog(@"%ld",connectStatus);
}



@end
