//
//  TLMessageImageView.m
//  TLChat
//
//  Created by 李伯坤 on 16/3/15.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLMessageImageView.h"
#import "TLImageDownloader.h"
#import <SDWebImage.h>

@interface TLMessageImageView ()

@property (nonatomic, weak) CAShapeLayer *maskLayer;

@property (nonatomic, weak) CALayer *contentLayer;

@end

@implementation TLMessageImageView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.contentsCenter = CGRectMake(0.5, 0.6, 0.1, 0.1);
        maskLayer.contentsScale = [UIScreen mainScreen].scale;                 //非常关键设置自动拉伸的效果且不变形
        CALayer *contentLayer = [[CALayer alloc] init];
        [contentLayer setMask:maskLayer];
        [self.layer addSublayer:contentLayer];
        
        self.maskLayer = maskLayer;
        self.contentLayer = contentLayer;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"delloc TLMessageImageView");
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.maskLayer setFrame:CGRectMake(0, 0, self.width, self.height)];
    [self.contentLayer setFrame:CGRectMake(0, 0, self.width, self.height)];
}

- (void)setThumbnailPath:(NSString *)imagePath highDefinitionImageURL:(NSString *)imageURL
{
    if (imagePath == nil) {
        UIImage *image = [UIImage imageWithColor:[UIColor grayColor]];
        [self.contentLayer setContents:(id)(image.CGImage)];
        @weakify(self)
        TLImageDownloader *downloader = [TLImageDownloader sharedDownloader];
        [downloader addDownloadTaskWithUrl:imageURL completeAction:^(BOOL success, UIImage *image) {
            @strongify(self)
            [self.contentLayer setContents:(id)(image.CGImage)];
        }];
        [downloader startDownload];
    }
    else {
        UIImage *image = [[UIImage imageNamed:imagePath] copy];
        [self.contentLayer setContents:(id)(image.CGImage)];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    UIImage *image = [backgroundImage copy];
    [self.maskLayer setContents:(id)image.CGImage];
}

@end
