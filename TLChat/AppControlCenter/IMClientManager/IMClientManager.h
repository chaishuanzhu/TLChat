//
//  IMClientManager.h
//  TLChat
//
//  Created by 飞鱼 on 2020/10/2.
//  Copyright © 2020 李伯坤. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMClientManager : NSObject

/*!
 * 取得本类实例的唯一公开方法。
 * <p>
 * 本类目前在APP运行中是以单例的形式存活，请一定注意这一点哦。
 *
 * @return IMClientManager
 */
+ (IMClientManager *)sharedInstance;

- (void)initMobileIMSDK;

- (void)releaseMobileIMSDK;


/**
 * 重置init标识。
 * <p>
 * <b>重要说明：</b>不退出APP的情况下，重新登陆时记得调用一下本方法，不然再
 * 次调用 {@link #initMobileIMSDK()} 时也不会重新初始化MobileIMSDK（
 * 详见 {@link #initMobileIMSDK()}代码）而报 code=203错误！
 *
 */
- (void)resetInitFlag;

@end

