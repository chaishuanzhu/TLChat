//
//  IMClientManager.m
//  TLChat
//
//  Created by 飞鱼 on 2020/10/2.
//  Copyright © 2020 李伯坤. All rights reserved.
//

#import "IMClientManager.h"
#import "ClientCoreSDK.h"
#import "ConfigEntity.h"
#import "TLMessageManager.h"

@interface IMClientManager ()

/* MobileIMSDK是否已被初始化. true表示已初化完成，否则未初始化. */
@property (nonatomic) BOOL _init;
//
@property (strong, nonatomic) TLMessageManager *messageListener;

@end

@implementation IMClientManager

// 本类的单例对象
static IMClientManager *instance = nil;

+ (IMClientManager *)sharedInstance
{
    if (instance == nil)
    {
        instance = [[super allocWithZone:NULL] init];
    }
    return instance;
}

/*
 *  重写init实例方法实现。
 *
 *  @return
 *  @see [NSObject init:]
 */
- (id)init
{
    if (![super init])
        return nil;

    [self initMobileIMSDK];

    return self;
}

- (void)initMobileIMSDK
{
    if(!self._init)
    {
        // 设置AppKey
        [ConfigEntity registerWithAppKey:@"5418023dfd98c579b6001741"];

        // 设置服务器ip和服务器端口
        [ConfigEntity setServerIp:@"192.168.2.100"];
        [ConfigEntity setServerPort:7901];

        // 使用以下代码表示不绑定固定port（由系统自动分配），否则使用默认的7801端口
//      [ConfigEntity setLocalUdpSendAndListeningPort:-1];

        // RainbowCore核心IM框架的敏感度模式设置
//        [ConfigEntity setSenseMode:SenseMode30S];

        // 开启DEBUG信息输出
        [ClientCoreSDK setENABLED_DEBUG:YES];

        // 设置事件回调
        self.messageListener = [TLMessageManager sharedInstance];
        [ClientCoreSDK sharedInstance].chatBaseEvent = self.messageListener;
        [ClientCoreSDK sharedInstance].chatMessageEvent = self.messageListener;
        [ClientCoreSDK sharedInstance].messageQoSEvent = self.messageListener;

        self._init = YES;
    }
}

- (void)releaseMobileIMSDK
{
    [[ClientCoreSDK sharedInstance] releaseCore];
    [self resetInitFlag];
}

- (void)resetInitFlag
{
    self._init = NO;
}

@end
