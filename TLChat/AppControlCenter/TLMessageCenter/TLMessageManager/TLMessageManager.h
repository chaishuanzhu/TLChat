//
//  TLMessageManager.h
//  TLChat
//
//  Created by 李伯坤 on 16/3/13.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ChatBaseEvent.h"
#import "ChatMessageEvent.h"
#import "MessageQoSEvent.h"
#import "CompletionDefine.h"

#import "TLDBMessageStore.h"
#import "TLDBConversationStore.h"
#import "TLMessage.h"

#import "TLMessageManagerChatVCDelegate.h"
#import "TLMessageManagerConvVCDelegate.h"

@interface TLMessageManager : NSObject<ChatBaseEvent, ChatMessageEvent, MessageQoSEvent>

/** 本Observer目前仅用于登陆时（因为登陆与收到服务端的登陆验证结果是异步的，所以有此观察者来完成收到验证后的处理）*/
@property (nonatomic, copy, nullable) ObserverCompletion loginOkForLaunchObserver;

@property (nonatomic, weak) id<TLMessageManagerChatVCDelegate> messageDelegate;
@property (nonatomic, weak) id<TLMessageManagerConvVCDelegate> conversationDelegate;

@property (nonatomic, strong, readonly) NSString *userID;

@property (nonatomic, strong) TLDBMessageStore *messageStore;

@property (nonatomic, strong) TLDBConversationStore *conversationStore;

+ (TLMessageManager *)sharedInstance;

#pragma mark - 发送
- (void)sendMessage:(TLMessage *)message
           progress:(void (^)(TLMessage *, CGFloat))progress
            success:(void (^)(TLMessage *))success
            failure:(void (^)(TLMessage *))failure;

- (int)loginWithID:(NSString *)uid
           andToken:(NSString *)token;
@end
