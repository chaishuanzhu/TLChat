//
//  TLAccountViewController.m
//  TLChat
//
//  Created by 李伯坤 on 2017/1/6.
//  Copyright © 2017年 李伯坤. All rights reserved.
//

#import "TLAccountViewController.h"
#import "TLLoginViewController.h"
#import "TLRegisterViewController.h"
#import "TLUserHelper.h"
#import "TLMessageManager.h"

#define     HEIGHT_BUTTON       50
#define     EDGE_BUTTON         35

typedef NS_ENUM(NSInteger, TLAccountButtonType) {
    TLAccountButtonTypeRegister,
    TLAccountButtonTypeLogin,
    TLAccountButtonTypeTest,
};

@interface TLAccountViewController ()

@property (nonatomic, copy) ObserverCompletion onLoginSucessObserver;

@end

@implementation TLAccountViewController

- (void)loadView {
    [super loadView];
    
    CGSize viewSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
    NSString *viewOrientation = @"Portrait";    //横屏请设置成 @"Landscape"
    NSArray *launchImages = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    NSString *launchImageName = nil;
    for (NSDictionary *dict in launchImages){
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]]) {
            launchImageName = dict[@"UILaunchImageName"];
        }
    }
    
    self.view.addImageView(1).image(TLImage(launchImageName))
    .masonry(^ (__kindof UIView *senderView, MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    });
   
    UIButton *(^createButton)(NSString *title, UIColor *bgColor, NSInteger tag) = ^UIButton *(NSString *title, UIColor *bgColor, NSInteger tag) {
        UIButton *button = UIButton.zz_create(tag)
        .backgroundColor(bgColor)
        .title(title).titleFont([UIFont systemFontOfSize:19])
        .cornerRadius(5.0f)
        .view;
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        return button;
    };
    
    // 注册按钮
    UIButton *registerButton = createButton(@"注 册", [UIColor redColor], TLAccountButtonTypeRegister);
    [self.view addSubview:registerButton];
    [registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(EDGE_BUTTON);
        make.bottom.mas_equalTo(-EDGE_BUTTON * 2);
        make.width.mas_equalTo((SCREEN_WIDTH - EDGE_BUTTON * 3) / 2);
        make.height.mas_equalTo(HEIGHT_BUTTON);
    }];
    
    // 登录按钮
    UIButton *loginButton = createButton(@"登 录", [UIColor colorGreenDefault], TLAccountButtonTypeLogin);
    [self.view addSubview:loginButton];
    [loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-EDGE_BUTTON);
        make.size.and.bottom.mas_equalTo(registerButton);
    }];
    
    
    // 测试按钮
    UIButton *testButton = createButton(@"使用测试账号登录", [UIColor clearColor], TLAccountButtonTypeTest);
    [testButton.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [self.view addSubview:testButton];
    [testButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-5);
        make.left.mas_equalTo(EDGE_BUTTON);
        make.right.mas_equalTo(-EDGE_BUTTON);
        make.height.mas_equalTo(HEIGHT_BUTTON);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self)
    self.onLoginSucessObserver = ^(id observerble, id data) {
        @strongify(self)
        [TLToast dismiss];
        // 服务端返回的登陆结果值
        int code = [(NSNumber *)data intValue];
        // 登陆成功
        if(code == 0)
        {
            // TODO 提示：登陆MobileIMSDK服务器成功后的事情在此实现即可
            // TODO 提示：登陆MobileIMSDK服务器成功后的事情在此实现即可
            // TODO 提示：登陆MobileIMSDK服务器成功后的事情在此实现即可
            // TODO 提示：登陆MobileIMSDK服务器成功后的事情在此实现即可
            // TODO 提示：登陆MobileIMSDK服务器成功后的事情在此实现即可

            // 进入主界面
//            self.loginSuccess();
            if (self.loginSuccess) {
                self.loginSuccess();
            }
        } else {// 登陆失败
            [TLAlertView showWithTitle:@"友情提示"
                               message:[NSString stringWithFormat:@"Sorry，登陆失败，错误码=%d", code] cancelButtonTitle:@"知道了"];
        }
        [[TLMessageManager sharedInstance] setLoginOkForLaunchObserver:nil];
    };
}

#pragma mark - # Event Response
- (void)buttonClicked:(UIButton *)sender
{
    if (sender.tag == TLAccountButtonTypeRegister) {
        TLRegisterViewController *registerVC = [[TLRegisterViewController alloc] init];
        TLWeakSelf(registerVC);
        TLWeakSelf(self);
        [registerVC setRegisterSuccess:^{
            [weakregisterVC dismissViewControllerAnimated:NO completion:nil];
            if (weakself.loginSuccess) {
                weakself.loginSuccess();
            }
        }];
        [self presentViewController:registerVC animated:YES completion:nil];
    }
    else if (sender.tag == TLAccountButtonTypeLogin) {
        TLLoginViewController *loginVC = [[TLLoginViewController alloc] init];
        TLWeakSelf(self);
        TLWeakSelf(loginVC);
        [loginVC setLoginSuccess:^{
            [weakloginVC dismissViewControllerAnimated:NO completion:nil];
            if (weakself.loginSuccess) {
                weakself.loginSuccess();
            }
        }];
        [self presentViewController:loginVC animated:YES completion:nil];
    }
    else if (sender.tag == TLAccountButtonTypeTest) {
        [[TLUserHelper sharedHelper] loginTestAccount];
        [self imLogin];
    }
}

- (void)imLogin {
    [TLToast showLoading:@"登录中。。。"];
    [[TLMessageManager sharedInstance] setLoginOkForLaunchObserver:self.onLoginSucessObserver];
    NSString *userID = [TLUserHelper sharedHelper].userID;
    int code = [[TLMessageManager sharedInstance] loginWithID:userID andToken:@"123456"];
    if (code == COMMON_CODE_OK) {
        DDLogDebug(@"[用户登录成功]uid----:%@",userID);
    } else {
        DDLogDebug(@"[用户登录失败]uid----:%@，error code：-----%d",userID, code);
    }
}

@end
