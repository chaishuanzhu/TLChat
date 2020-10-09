//
//  TLMessageManager.m
//  TLChat
//
//  Created by 李伯坤 on 16/3/13.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLMessageManager.h"
#import "TLMessageManager+ConversationRecord.h"
#import "TLUserHelper.h"
#import "TLNetwork.h"

#import "TLFriendHelper.h"
#import "TLTextMessage.h"
#import "TLImageMessage.h"
#import "TLVoiceMessage.h"

#import "LocalDataSender.h"
#import "NSFileManager+TLChat.h"
#import <AFNetworking/AFNetworking.h>
#import "IMResponse.h"

static TLMessageManager *messageManager;

@implementation TLMessageManager

+ (TLMessageManager *)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        messageManager = [[TLMessageManager alloc] init];
    });
    return messageManager;
}

- (void)sendMessage:(TLMessage *)message
           progress:(void (^)(TLMessage *, CGFloat))progress
            success:(void (^)(TLMessage *))success
            failure:(void (^)(TLMessage *))failure
{
    // 图灵机器人
//    [self p_sendMessageToReboot:message];


    if (message.messageType == TLMessageTypeImage) {
        TLImageMessage *msg = (TLImageMessage *)message;
        NSString *url = @"http://192.168.2.100:8888/file/upload";
        TLUploadRequest *request = [[TLUploadRequest alloc]initWithMethod:TLRequestMethodPOST url:url parameters:nil];
        request.dataPath = msg.imagePath;
        @weakify(self)
        request.uploadProgressAction = ^(NSProgress *prog) {
            @strongify(self)
            progress(message, (CGFloat)prog.completedUnitCount/prog.totalUnitCount);
        };
        request.constructingBodyAction = ^(id<AFMultipartFormData> formData) {
            NSString *imagePath = [NSFileManager pathUserChatImage:[msg imagePath]];
            [formData appendPartWithFileData:[NSData dataWithContentsOfFile:imagePath] name:@"file" fileName:msg.imagePath mimeType: @"image/jpeg"];
        };
        [request startRequestWithSuccessAction:^(TLResponse *response) {
            @strongify(self)
            DDLogDebug(@"%@", response.responseString);
            IMResponse *res = [IMResponse mj_objectWithKeyValues:response.responseData];
            if (res.isok) {
                msg.imageURL = res.data;
                [self sendMessage:msg success:success failure:failure];
            }
        } failureAction:^(TLResponse *response) {
            DDLogError(@"%@", response.error);
        }];
    } else if (message.messageType == TLMessageTypeVoice) {
        TLVoiceMessage *msg = (TLVoiceMessage *)message;
        NSString *url = @"http://192.168.2.100:8888/file/upload";
        TLUploadRequest *request = [[TLUploadRequest alloc]initWithMethod:TLRequestMethodPOST url:url parameters:nil];
        request.dataPath = msg.path;
        @weakify(self)
        request.uploadProgressAction = ^(NSProgress *prog) {
            @strongify(self)
            progress(message, (CGFloat)prog.completedUnitCount/prog.totalUnitCount);
        };
        request.constructingBodyAction = ^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:[NSData dataWithContentsOfFile:msg.path] name:@"file" fileName:[msg.path lastPathComponent] mimeType: @"audio/ima4"];
        };
        [request startRequestWithSuccessAction:^(TLResponse *response) {
            @strongify(self)
            DDLogDebug(@"%@", response.responseString);
            IMResponse *res = [IMResponse mj_objectWithKeyValues:response.responseData];
            if (res.isok) {
                msg.url = res.data;
                [self sendMessage:msg success:success failure:failure];
            }
        } failureAction:^(TLResponse *response) {
            DDLogError(@"%@", response.error);
        }];
    } else {
        [self sendMessage:message success:success failure:failure];
    }
}

- (void)sendMessage:(TLMessage *)message success:(void (^)(TLMessage *))success failure:(void (^)(TLMessage *))failure {
    BOOL code = [[LocalDataSender sharedInstance] sendCommonDataWithStr:message.content.mj_JSONString toUserId:message.friendID withTypeu:message.messageType];

    if (code == 0) {
        DDLogDebug(@"消息已发送成功");
    } else {
        DDLogError(@"消息发送失败，错误码： %d", code);
    }

    BOOL ok = [self.messageStore addMessage:message];
    if (!ok) {
        DDLogError(@"存储Message到DB失败");
    }
    else {      // 存储到conversation
        ok = [self addConversationByMessage:message];
        if (!ok) {
            DDLogError(@"存储Conversation到DB失败");
        }
    }
}

- (int)loginWithID:(NSString *)uid andToken:(NSString *)token {
    int code = [[LocalDataSender sharedInstance] sendLogin:uid withToken:token];
    return code;
}

#pragma mark - # Private
- (void)p_sendMessageToReboot:(TLMessage *)message
{
    if (message.messageType == TLMessageTypeText) {
        // 聊天的用户
        TLUser *user;
        if (message.partnerType == TLPartnerTypeGroup) {
            TLGroup *group = [[TLFriendHelper sharedFriendHelper] getGroupInfoByGroupID:message.groupID];
            NSInteger index = arc4random() % group.count;
            user = group.users[index];
        }
        else {
            user = [[TLFriendHelper sharedFriendHelper] getFriendInfoByUserID:message.friendID];
        }
        
        NSString *text = [message.content objectForKey:@"text"];
        NSString *apiKey = ({
            NSString *key;
            if ([user.userID isEqualToString:@"1001"]) {   // 曾小贤
                key = @"00916307c7b24533a23d6115224540f3";
            }
            else if ([user.userID isEqualToString:@"1002"]) {   // 陈美嘉
                key = @"5f5f8d7d613f4d81a6ff354cb428ccbc";
            }
            else {
                key = @"44eb0b4ab0a640f192bd469551a7c03e";
            }
            key;
        });
        NSDictionary *json = @{@"reqType" : @"0",
                               @"userInfo" : @{
                                       @"apiKey" : apiKey,
                                       @"userId" : @"100454",
                                       },
                               @"perception" : @{
                                       @"inputText" : @{
                                               @"text" : text,
                                               }
                                       },
                               };
        NSString *url = @"http://openapi.tuling123.com/openapi/api/v2";
        TLBaseRequest *request = [TLBaseRequest requestWithMethod:TLRequestMethodPOST url:url parameters:json];
        [request startRequestWithSuccessAction:^(TLResponse *response) {
            NSDictionary *json = response.responseObject;
            NSArray *results = [json objectForKey:@"results"];
            for (NSDictionary *item in results) {
                NSDictionary *values = [item objectForKey:@"values"];
                if (values[@"text"]) {
                    NSString *text = values[@"text"];
                    TLTextMessage *textMessage = [[TLTextMessage alloc] init];
                    textMessage.partnerType = message.partnerType;
                    textMessage.text = text;
                    textMessage.ownerTyper = TLMessageOwnerTypeFriend;
                    textMessage.userID = message.userID;
                    textMessage.date = [NSDate date];
                    textMessage.friendID = user.userID;
                    textMessage.fromUser = (id <TLChatUserProtocol>)user;
                    textMessage.groupID = message.groupID;
                    [self.messageStore addMessage:textMessage];
                    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(didReceivedMessage:)]) {
                        [self.messageDelegate didReceivedMessage:textMessage];
                    }
                }
                else if (values[@"image"]) {
                    NSString *imageURL = values[@"image"];
                    TLImageMessage *imageMessage = [[TLImageMessage alloc] init];
                    imageMessage.partnerType = message.partnerType;
                    imageMessage.imageURL = imageURL;
                    imageMessage.ownerTyper = TLMessageOwnerTypeFriend;
                    imageMessage.userID = message.userID;
                    imageMessage.friendID = user.userID;
                    imageMessage.date = [NSDate date];
                    imageMessage.fromUser = (id <TLChatUserProtocol>)user;
                    imageMessage.imageSize = CGSizeMake(120, 120);
                    imageMessage.groupID = message.groupID;
                    [self.messageStore addMessage:imageMessage];
                    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(didReceivedMessage:)]) {
                        [self.messageDelegate didReceivedMessage:imageMessage];
                    }
                }
            }
        } failureAction:^(TLResponse *response) {
            NSLog(@"failure");
        }];
    }
}

#pragma mark - # Getters
- (TLDBMessageStore *)messageStore
{
    if (_messageStore == nil) {
        _messageStore = [[TLDBMessageStore alloc] init];
    }
    return _messageStore;
}

- (TLDBConversationStore *)conversationStore
{
    if (_conversationStore == nil) {
        _conversationStore = [[TLDBConversationStore alloc] init];
    }
    return _conversationStore;
}

- (NSString *)userID
{
    return [TLUserHelper sharedHelper].userID;
}


/// MARK:- 与IM服务器的连接事件ChatBaseEvent
/*!
 * 本地用户的登陆结果回调事件通知。
 *
 * @param errorCode 服务端反馈的登录结果：0 表示登陆成功，否则为服务端自定义的出错代码（按照约定通常为>=1025的数）
 */
- (void) onLoginResponse:(int)errorCode
{
    if (errorCode == 0)
    {
        DDLogDebug(@"【DEBUG_UI】IM服务器登录/连接成功！");

        // UI显示
//        [CurAppDelegate refreshConnecteStatus];
//        [[CurAppDelegate getMainViewController] showIMInfo_green:[NSString stringWithFormat:@"登录成功,errorCode=%d", errorCode]];
    }
    else
    {
        DDLogError(@"【DEBUG_UI】IM服务器登录/连接失败，错误代码：%d", errorCode);

//        // UI显示
//        [[CurAppDelegate getMainViewController] showIMInfo_red:[NSString stringWithFormat:@"IM服务器登录/连接失败,code=%d", errorCode]];
    }

    // 此观察者只有开启程序首次使用登陆界面时有用
    if(self.loginOkForLaunchObserver != nil)
    {
        self.loginOkForLaunchObserver(nil, [NSNumber numberWithInt:errorCode]);

        //## Try bug FIX! 20160810：上方的observer作为block代码应是被异步执行，此处立即设置nil的话，实测
        //##                        中会遇到怎么也登陆不进去的问题（因为此observer已被过早的nil了！）
//        self.loginOkForLaunchObserver = nil;
    }
}

/*!
 * 与服务端的通信断开的回调事件通知。
 *
 * <br>
 * 该消息只有在客户端连接服务器成功之后网络异常中断之时触发。
 * 导致与与服务端的通信断开的原因有（但不限于）：无线网络信号不稳定、WiFi与2G/3G/4G等同开情
 * 况下的网络切换、手机系统的省电策略等。
 *
 * @param errorCode 本回调参数表示表示连接断开的原因，目前错误码没有太多意义，仅作保留字段，目前通常为-1
 */
- (void) onLinkClose:(int)errorCode
{
    DDLogError(@"【DEBUG_UI】与IM服务器的网络连接出错关闭了，error：%d", errorCode);

    // UI显示
//    [CurAppDelegate refreshConnecteStatus];
//    [[CurAppDelegate getMainViewController] showIMInfo_red:[NSString stringWithFormat:@"与IM服务器的连接已断开, 自动登陆/重连将启动! (%d)", errorCode]];
}

/// MARK:- 与IM服务器的数据交互事件ChatTransDataEvent

/*!
 * 收到普通消息的回调事件通知。
 * <br>
 * 应用层可以将此消息进一步按自已的IM协议进行定义，从而实现完整的即时通信软件逻辑。
 *
 * @param fingerPrintOfProtocal 当该消息需要QoS支持时本回调参数为该消息的特征指纹码，否则为null
 * @param dwUserid 消息的发送者id（RainbowCore框架中规定发送者id=“0”即表示是由服务端主动发过的，否则表示的是其它客户端发过来的消息）
 * @param dataContent 消息内容的文本表示形式
 */
- (void) onRecieveMessage:(NSString *)fingerPrintOfProtocal withUserId:(NSString *)dwUserid andContent:(NSString *)dataContent andTypeu:(int)typeu
{
    DDLogDebug(@"【DEBUG_UI】[%d]收到来自用户%@的消息:%@", typeu, dwUserid, dataContent);
    TLUser *user = [[TLFriendHelper sharedFriendHelper] getFriendInfoByUserID:dwUserid];

    TLMessage *message = [TLMessage createMessageByType:typeu];
    message.partnerType = TLPartnerTypeUser;
    message.content = [dataContent.mj_JSONObject mutableCopy];
    message.ownerTyper = TLMessageOwnerTypeFriend;
    message.userID = [[TLUserHelper sharedHelper]userID];
    message.date = [NSDate date];
    message.friendID = dwUserid;
    message.fromUser = (id <TLChatUserProtocol>)user;

    BOOL ok = [self.messageStore addMessage:message];
    if (!ok) {
        DDLogError(@"存储Message到DB失败");
    }
    else {      // 存储到conversation
        ok = [self addConversationByMessage:message];
        if (!ok) {
            DDLogError(@"存储Conversation到DB失败");
        }
    }

    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(didReceivedMessage:)]) {
        [self.messageDelegate didReceivedMessage:message];
    }
    if (self.conversationDelegate && [self.conversationDelegate respondsToSelector:@selector(updateConversationData)]) {
        [self.conversationDelegate updateConversationData];
    }

    // UI显示
    // Make toast with an image & title
//    [[CurAppDelegate getMainView] makeToast:dataContent
//                duration:3.0
//                position:@"center"
//                   title:[NSString stringWithFormat:@"%@说：", dwUserid]
//                   image:[UIImage imageNamed:@"qzone_mark_img_myvoice.png"]];
//    [[CurAppDelegate getMainViewController] showIMInfo_black:[NSString stringWithFormat:@"%@说：%@", dwUserid, dataContent]];
}

/*!
 * 服务端反馈的出错信息回调事件通知。
 *
 * @param errorCode 错误码，定义在常量表 ErrorCode 中有关服务端错误码的定义
 * @param errorMsg 描述错误内容的文本信息
 * @see ErrorCode
 */
- (void) onErrorResponse:(int)errorCode withErrorMsg:(NSString *)errorMsg
{
    NSLog(@"【DEBUG_UI】收到服务端错误消息，errorCode=%d, errorMsg=%@", errorCode, errorMsg);

    // UI显示
    if(errorCode == ForS_RESPONSE_FOR_UNLOGIN)
    {
//        NSString *content = [NSString stringWithFormat:@"服务端会话已失效，自动登陆/重连将启动! (%d)", errorCode];
//        [[CurAppDelegate getMainViewController] showIMInfo_brightred:content];
    }
    else
    {
//        NSString *content = [NSString stringWithFormat:@"Server反馈错误码：%d,errorMsg=%@", errorCode, errorMsg];
//        [[CurAppDelegate getMainViewController] showIMInfo_red:content];
    }
}

/// MARK:- 消息送达相关事件（由QoS机制通知上来的）MessageQoSEvent
/*!
 * 消息未送达的回调事件通知.
 *
 * @param lostMessages 由MobileIMSDK QoS算法判定出来的未送达消息列表（此列表
 * 中的Protocal对象是原对象的clone（即原对象的深拷贝），请放心使用哦），应用层
 * 可通过指纹特征码找到原消息并可以UI上将其标记为”发送失败“以便即时告之用户
 */
- (void) messagesLost:(NSMutableArray*)lostMessages
{
    DDLogDebug(@"【DEBUG_UI】收到系统的未实时送达事件通知，当前共有%li个包QoS保证机制结束，判定为【无法实时送达】！", (unsigned long)[lostMessages count]);

    // UI显示
//    [[CurAppDelegate getMainViewController] showIMInfo_brightred:[NSString stringWithFormat:@"[消息未成功送达]共%li条!(网络状况不佳或对方id不存在)", [lostMessages count]]];
}

/*!
 * 消息已被对方收到的回调事件通知.
 * <p>
 * <b>目前，判定消息被对方收到是有两种可能：</b>
 * <br>
 * 1) 对方确实是在线并且实时收到了；<br>
 * 2) 对方不在线或者服务端转发过程中出错了，由服务端进行离线存储成功后的反馈
 * （此种情况严格来讲不能算是“已被收到”，但对于应用层来说，离线存储了的消息
 * 原则上就是已送达了的消息：因为用户下次登陆时肯定能通过HTTP协议取到）。
 *
 * @param theFingerPrint 已被收到的消息的指纹特征码（唯一ID），应用层可据此ID
 * 来找到原先已发生的消息并可在UI是将其标记为”已送达“或”已读“以便提升用户体验
 */
- (void) messagesBeReceived:(NSString *)theFingerPrint
{
    if(theFingerPrint != nil)
    {
        DDLogDebug(@"【DEBUG_UI】收到对方已收到消息事件的通知，fp=%@", theFingerPrint);

        // UI显示
//        [[CurAppDelegate getMainViewController] showIMInfo_blue:[NSString stringWithFormat:@"[收到应答]%@", theFingerPrint]];
    }
}

@end
