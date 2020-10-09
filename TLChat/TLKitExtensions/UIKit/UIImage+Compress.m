//
//  UIImage+Compress.m
//  TLChat
//
//  Created by 飞鱼 on 2020/10/4.
//  Copyright © 2020 李伯坤. All rights reserved.
//

#import "UIImage+Compress.h"
#import <SDWebImageWebPCoder.h>

@implementation UIImage (Compress)

- (NSData *)compress {
    /** 仿微信算法 **/
    int width = (int)self.size.width;
    int height = (int)self.size.height;
    int updateWidth = width;
    int updateHeight = height;
    int longSide = MAX(width, height);
    int shortSide = MIN(width, height);
    float scale = ((float) shortSide / longSide);

    // 大小压缩
    if (shortSide < 1080 || longSide < 1080) { // 如果宽高任何一边都小于 1080
        updateWidth = width;
        updateHeight = height;
    } else { // 如果宽高都大于 1080
        if (width < height) { // 说明短边是宽
            updateWidth = 1080;
            updateHeight = 1080 / scale;
        } else { // 说明短边是高
            updateWidth = 1080 / scale;
            updateHeight = 1080;
        }
    }

    CGSize compressSize = CGSizeMake(updateWidth, updateHeight);
    UIGraphicsBeginImageContext(compressSize);
    [self drawInRect:CGRectMake(0,0, compressSize.width, compressSize.height)];
    UIImage *compressImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSData *compressData = UIImageJPEGRepresentation(compressImage, 0.5);
    return compressData;
}

- (NSData *)webpEncode {
    NSData *limitedWebpData = [[SDImageWebPCoder sharedCoder] encodedDataWithImage:self format:SDImageFormatWebP options:@{
        SDImageCoderEncodeMaxPixelSize: @(CGSizeMake(1080, 1080)),
        SDImageCoderEncodeCompressionQuality: @(0.75),
        SDImageCoderEncodeMaxFileSize : @(1024 * 512)
    }];
    return limitedWebpData;
}

@end
