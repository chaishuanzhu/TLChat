//
//  UIImage+Compress.h
//  TLChat
//
//  Created by 飞鱼 on 2020/10/4.
//  Copyright © 2020 李伯坤. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Compress)

- (NSData *)compress;

- (NSData *)webpEncode;

@end

NS_ASSUME_NONNULL_END
