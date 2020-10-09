//
//  IMResponse.h
//  TLChat
//
//  Created by 飞鱼 on 2020/10/4.
//  Copyright © 2020 李伯坤. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMResponse : NSObject

@property (nonatomic, assign) BOOL isok;
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) id data;

@end

NS_ASSUME_NONNULL_END
