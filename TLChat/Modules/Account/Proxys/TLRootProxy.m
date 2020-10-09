//
//  TLRootProxy.m
//  TLChat
//
//  Created by 李伯坤 on 16/3/13.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLRootProxy.h"
#import "TLMacros.h"
#import "TLNetworking.h"
#import "TLUserHelper.h"
#import "TLMessageManager.h"

#define     URL_LOGIN           @"user/login/"
#define     URL_REGISTER        @"user/register/"

@implementation TLRootProxy

- (void)requestClientInitInfoSuccess:(void (^)(id)) clientInitInfo
                             failure:(void (^)(NSString *))error
{
//    NSString *urlString = [TLHost clientInitInfoURL];
//    [TLNetworking postUrl:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
//        NSLog(@"OK");
//    } failure:^(NSURLSessionDataTask *task, NSError *error) {
//        NSLog(@"NO");
//    }];
}

- (void)userLoginWithPhoneNumber:(NSString *)phoneNumber
                        password:(NSString *)password
                         success:(TLBlockRequestSuccessWithDatas)success
                         failure:(TLBlockRequestFailureWithErrorMessage)failure
{
    NSString *url = [HOST_URL stringByAppendingString:URL_LOGIN];
    NSDictionary *params = @{@"phone" : phoneNumber,
                             @"password" : password};
    [TLNetworking postUrl:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *json = [responseObject mj_JSONObject];
        BOOL isok = [json[@"isok"] boolValue];
        if (isok) {
            NSDictionary *data = json[@"data"];
            NSString *token = data[@"password"];
            TLUser *user = [TLUser mj_objectWithKeyValues:data];
            [[TLUserHelper sharedHelper]setUser:user];
            [[TLMessageManager sharedInstance]loginWithID:[TLUserHelper sharedHelper].userID andToken:@"123456"];
            if (success) {
                success(token);
            }
        }
        else {
            NSString *errorMsg = json[@"message"];
            if (failure) {
                failure(errorMsg);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(@"网络请求失败");
        }
    }];
}

- (void)userRegisterWithPhoneNumber:(NSString *)phoneNumber
                           password:(NSString *)password
                            success:(TLBlockRequestSuccessWithDatas)success
                            failure:(TLBlockRequestFailureWithErrorMessage)failure
{
    NSString *url = [HOST_URL stringByAppendingString:URL_REGISTER];
    NSDictionary *params = @{@"phone" : phoneNumber,
                             @"password" : password};
    [TLNetworking postUrl:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *json = [responseObject mj_JSONObject];
        BOOL isOK = [json[@"isok"] boolValue];
        if (isOK) {
            NSDictionary *data = json[@"data"];
            NSString *token = data[@"token"];
            TLUser *user = [TLUser mj_objectWithKeyValues:data];
            [[TLUserHelper sharedHelper]setUser:user];
            [[TLMessageManager sharedInstance]loginWithID:[TLUserHelper sharedHelper].userID andToken:@"123456"];
            if (success) {
                success(token);
            }
        }
        else {
            NSString *errorMsg = json[@"message"];
            if (failure) {
                failure(errorMsg);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(@"网络请求失败");
        }
    }];
}

@end
