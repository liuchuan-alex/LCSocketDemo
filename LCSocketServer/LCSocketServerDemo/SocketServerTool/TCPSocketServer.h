//
//  TCPSocketServer.h
//  LCSocketServerDemo
//
//  Created by 刘川 on 2018/12/19.
//  Copyright © 2018 alex. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCPSocketServer : NSObject


/**
 获取单例
 
 @return id
 */
+ (instancetype)shareInstance;



/**
 开启服务器
 
 @param port 端口号
 */
- (void)openSerViceWithPort:(uint16_t) port;


/**
 给客户端发送数据

 @param data 十六进制数据
 */
- (void)sendData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
