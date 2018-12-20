//
//  ViewController.m
//  LCSocketServerDemo
//
//  Created by 刘川 on 2018/12/19.
//  Copyright © 2018 alex. All rights reserved.
//

#import "ViewController.h"
#import "TCPSocketServer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    //  开启监听
    [[TCPSocketServer shareInstance] openSerViceWithPort:8888];
}


@end
