//
//  TLGameViewController.m
//  TLChat
//
//  Created by 李伯坤 on 16/3/4.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLGameViewController.h"

@implementation TLGameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUseMPageTitleAsNavTitle:NO];
    [self setShowLoadingProgress:NO];
    [self setDisableBackButton:YES];
    
    [self.navigationItem setTitle:LOCSTR(@"游戏")];
    [self setUrl:@"http://m.le890.com"];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_setting"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonDown:)];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
    [TLToast showLoading:@"加载中"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([TLToast isVisible]) {
        [TLToast dismiss];
    }
}

#pragma mark - Delegate -
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if ([TLToast isVisible]) {
        [TLToast dismiss];
    }
    [super webView:webView didFinishNavigation:navigation];
}

#pragma mark - Event Response
- (void)rightBarButtonDown:(UIBarButtonItem *)sender
{
    
}

@end