//
//  TCPSocketClient.m
//  LCSocketClientDemo
//
//  Created by 刘川 on 2018/12/19.
//  Copyright © 2018 alex. All rights reserved.

#import "TCPSocketClient.h"
#import "GCDAsyncSocket.h"


@interface TCPSocketClient()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property(nonatomic, strong) NSTimer *heartbeatTimer;
@property(nonatomic, assign) BOOL isConnection;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) uint16_t port;
@property(nonatomic,  weak) id delegate;

@end

@implementation TCPSocketClient


+ (instancetype)sharedSocket{
    static TCPSocketClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance=[[self alloc] init];
    });
    return sharedInstance;
}

- (void)connectServerWithDelegate:(id) delegate ToHost:(NSString *)host onPort:(uint16_t)port{
    
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.delegate = delegate;
    self.host = host;
    self.port = port;
    [self connectServer];
}

- (void)connectServer{
    
//    [self.clientSocket disconnect];
    NSError *error=nil;
    [self.clientSocket connectToHost:self.host onPort:self.port error:&error];
    if (error) {
        NSLog(@"socketError--%@",error);
    }
}

- (void)disConnectServer{

    self.isConnection = NO;
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    if ([self.delegate respondsToSelector:@selector(socket:SocketConnectStatus:)]) {
        [self.delegate socket:self SocketConnectStatus:SocketConnectStatusDisconnected];
    }
    [self.clientSocket disconnect];
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
}

- (void)sendData:(NSData *)data{

    if (self.isConnection) {
        
        NSMutableData *sendData = [NSMutableData data];
        // 获取数据长度
        NSInteger datalength = data.length;
        //  NSInteger长度转 NSData
        NSData *lengthData = [NSData dataWithBytes:&datalength length:sizeof(datalength)];
        // 长度几个字节和服务器协商好。这里我们用的是4个字节存储长度信息
        NSData *newLengthData = [lengthData subdataWithRange:NSMakeRange(0, 4)];
        // 拼接长度信息
        [sendData appendData:newLengthData];
        [sendData appendData:data];
        
        [self.clientSocket writeData:sendData withTimeout:-1 tag:0];
    }
}

- (BOOL)isConnection{
    return _isConnection;
}

- (void)beginSendHeartbeat{
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(sendHeartbeat:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
}

- (void)sendHeartbeat:(NSTimer *)timer {
    if (timer != nil) {
        
        char heartbeat[4] = {0xab,0xcd,0x00,0x00}; // 心跳字节，和服务器协商
        NSData *heartbeatData = [NSData dataWithBytes:&heartbeat length:sizeof(heartbeat)];
        //  心跳包前面也加入长度，用于拆包
        int length = 4;
        NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(length)];
        NSMutableData *newheartbeatData = [NSMutableData dataWithData:lengthData];
        [newheartbeatData appendData:heartbeatData];
        
        [self.clientSocket writeData:newheartbeatData withTimeout:-1 tag:0];
    }
}

#pragma mark - GCDSocketDelegate

- (void)socket:(GCDAsyncSocket*)sock didConnectToHost:(NSString*)host port:(UInt16)port{
    
    NSLog(@"--连接成功--");
    self.isConnection = YES;
    if ([self.delegate respondsToSelector:@selector(socket:SocketConnectStatus:)]) {
        [self.delegate socket:self SocketConnectStatus:SocketConnectStatusConnected];
    }
    [sock readDataWithTimeout:-1 tag:0];
    [self beginSendHeartbeat];
}


- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err{
    
    NSLog(@"--断开连接--");
    self.isConnection = NO;
    if ([self.delegate respondsToSelector:@selector(socket:SocketConnectStatus:)]) {
        [self.delegate socket:self SocketConnectStatus:SocketConnectStatusDisconnected];
    }
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    NSString *serverStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"服务端回包了--回包内容--%@---长度%lu",serverStr,(unsigned long)data.length);
    if ([self.delegate respondsToSelector:@selector(socket:didReadData:)]) {
        [self.delegate socket:self didReadData:data];
    }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"%ld",tag);
    

}

@end
