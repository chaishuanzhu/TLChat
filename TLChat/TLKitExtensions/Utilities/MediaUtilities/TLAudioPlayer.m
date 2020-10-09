//
//  TLAudioPlayer.m
//  TLChat
//
//  Created by 李伯坤 on 16/7/12.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "NSFileManager+TLChat.h"

@interface TLAudioPlayer() <AVAudioPlayerDelegate>

@property (nonatomic, strong) void (^ completeBlock)(BOOL finished);

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation TLAudioPlayer

+ (TLAudioPlayer *)sharedAudioPlayer
{
    static TLAudioPlayer *audioPlayer;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        audioPlayer = [[TLAudioPlayer alloc] init];
    });
    return audioPlayer;
}

- (void)playAudioAtPath:(NSString *)path complete:(void (^)(BOOL finished))complete;
{
    if (self.player && self.player.isPlaying) {
        [self stopPlayingAudio];
    }
    self.completeBlock = complete;
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    [self.player setDelegate:self];
    if (error) {
        if (complete) {
            complete(NO);
        }
        return;
    }
    [self.player play];
}

- (void)playAudioAtURL:(NSString *)url complete:(void (^)(BOOL))complete {
    NSString *path = [NSFileManager pathUserChatVoice:url.lastPathComponent];
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath: path];
    if (isExists) {
        [self playAudioAtPath:path complete:complete];
    } else {
        @weakify(self)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @strongify(self)
            NSData *data = [NSData dataWithContentsOfURL:TLURL(url)];
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self playAudioAtPath:path complete:complete];
                });
            } else {
                DDLogError(@"录音文件下载失败");
            }
        });
    }
}

- (void)stopPlayingAudio
{
    [self.player stop];
    if (self.completeBlock) {
        self.completeBlock(NO);
    }
}

- (BOOL)isPlaying
{
    if (self.player) {
        return self.player.isPlaying;
    }
    return NO;
}

#pragma mark - # Delegate
//MARK: AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (self.completeBlock) {
        self.completeBlock(YES);
        self.completeBlock = nil;
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    DDLogError(@"音频播放出现错误：%@", error);
    if (self.completeBlock) {
        self.completeBlock(NO);
        self.completeBlock = nil;
    }
}

@end
