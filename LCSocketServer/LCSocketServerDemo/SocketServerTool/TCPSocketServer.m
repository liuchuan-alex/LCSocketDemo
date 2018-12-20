//
//  TCPSocketServer.m
//  LCSocketServerDemo
//
//  Created by 刘川 on 2018/12/19.
//  Copyright © 2018 alex. All rights reserved.
//

#import "TCPSocketServer.h"
#import "GCDAsyncSocket.h"

@interface TCPSocketServer ()<GCDAsyncSocketDelegate>

/**
 GCDAsyncSocket 实例
 */
@property(nonatomic, strong) GCDAsyncSocket *serverSocket;
/**
 检查心跳包线程
 */
@property(nonatomic, strong) NSThread *checkThread;

/**
 连接客户端数组
 */
@property(nonatomic, strong) NSMutableArray *arrayClient;

/**
 记录心跳缓存
 */
@property (nonatomic, strong) NSMutableDictionary *heartbeatDateDict;

/**
 数据缓冲区
 */
@property (nonatomic, strong) NSMutableData *dataBuffer;;


@end

@implementation TCPSocketServer

+ (instancetype)shareInstance{
    
    static TCPSocketServer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance= [[TCPSocketServer alloc] init];
        sharedInstance.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:sharedInstance delegateQueue:dispatch_get_main_queue()];
        //  开启个常驻线程不断检测所连接的每个客户端的心跳
        sharedInstance.checkThread = [[NSThread alloc]initWithTarget:sharedInstance selector:@selector(checkClientOnline) object:nil];
        [sharedInstance.checkThread start];
    });
    return sharedInstance;
}

- (void)openSerViceWithPort:(uint16_t) port{
    //  开放服务端的指定端口.
    NSError *error = nil;
    BOOL result = [self.serverSocket acceptOnPort:port error:&error];
    
    if (result) {
        NSLog(@"端口开启成功,并监听客户端请求连接...");
    }else {
        NSLog(@"端口开启失...");
    }
}

- (void)sendData:(NSData *)data{
    [self.serverSocket writeData:data withTimeout:-1 tag:0];
}

- (void)handleData:(NSData *) data socket:(GCDAsyncSocket* ) sock{
    
    //  记录客户端心跳
    char heartbeat[4] = {0xab,0xcd,0x00,0x00}; // 心跳字节，和服务器协商
    NSData *heartbeatData = [NSData dataWithBytes:&heartbeat length:sizeof(heartbeat)];
    if ([data isEqualToData:heartbeatData]) {
        NSLog(@"*************心跳**************");
        self.heartbeatDateDict[sock.connectedHost] = [NSDate date];
    }else{
        NSString *clientStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"客户端内容--%@---长度%lu",clientStr,(unsigned long)data.length);
    }
}

#pragma -mark GCDAsyncSocketDelegate

//  连接上新的客户端socket
- (void)socket:(GCDAsyncSocket *)serveSock didAcceptNewSocket:(GCDAsyncSocket *) newSocket{
    
    NSLog(@"%@ IP: %@: %hu 客户端请求连接...",newSocket,newSocket.connectedHost,newSocket.localPort);
    // 将客户端socket保存起来
    if (![self.arrayClient containsObject:newSocket]) {
        [self.arrayClient addObject:newSocket];
    }
    [newSocket readDataWithTimeout:-1 tag:0];
}

//  读取客户端发送的数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
        //  数据存入缓冲区
        [self.dataBuffer appendData:data];
        
        // 如果长度大于4个字节，表示有数据包。4字节为包头，存储包内数据长度
        while (self.dataBuffer.length >= 4) {
            
            NSInteger  datalength = 0;
            // 获取包头，并获取长度
            [[self.dataBuffer subdataWithRange:NSMakeRange(0, 4)] getBytes:&datalength length:sizeof(datalength)];
            //  判断缓存区内是否有包
            if (self.dataBuffer.length >= (datalength+4)) {
                // 获取去掉包头的数据
                NSData *realData = [[self.dataBuffer subdataWithRange:NSMakeRange(4, datalength)] copy];
                // 解析处理
                [self handleData:realData socket:sock];
                
                // 移除已经拆过的包
                self.dataBuffer = [NSMutableData dataWithData:[self.dataBuffer subdataWithRange:NSMakeRange(datalength+4, self.dataBuffer.length - (datalength+4))]];
            }else{
                break;
            }
        }
        [sock readDataWithTimeout:-1 tag:0];
}

//  断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    
    NSLog(@"断开连接");
}

#pragma checkTimeThread

//  这里设置10检查一次 数组里所有的客户端socket 最后一次通讯时间,这样的话会有周期差（最多差10s），可以设置为1s检查一次，这样频率快
//  开启线程 启动runloop 循环检测客户端socket最新time
- (void)checkClientOnline{
    
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(repeatCheckClinetOnline) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]run];
    }
}

//  移除 超过心跳时差的 client
- (void)repeatCheckClinetOnline{
    
    if (self.arrayClient.count == 0) {
        return;
    }
    NSDate *date = [NSDate date];
    for (GCDAsyncSocket *socket in self.arrayClient ) {
        if ([date timeIntervalSinceDate:self.heartbeatDateDict[socket.connectedHost]]>10) {
            [self.arrayClient removeObject:socket];
        }
    }
}

#pragma -mark lazy load
- (NSMutableArray *)arrayClient{
    if (!_arrayClient) {
        _arrayClient = [NSMutableArray array];
    }
    return _arrayClient;
}

- (NSMutableDictionary *)heartbeatDateDict{
    if (!_heartbeatDateDict) {
        _heartbeatDateDict = [NSMutableDictionary dictionary];
    }
    return _heartbeatDateDict;
}

- (NSMutableData *)dataBuffer{
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}


@end
