//
//  TLMineInfoViewController.m
//  TLChat
//
//  Created by 李伯坤 on 16/2/10.
//  Copyright © 2016年 李伯坤. All rights reserved.
//

#import "TLMineInfoViewController.h"
#import "TLMyQRCodeViewController.h"
#import "TLUserHelper.h"
#import "TLSettingItem.h"
#import "TLSettingItemTemplate.h"
#import "TLMineInfoAvatarCell.h"

#import "NSFileManager+TLChat.h"
#import <TZImagePickerController.h>
#import <AFNetworking.h>
#import "TLNetworking.h"

typedef NS_ENUM(NSInteger, TLMineInfoVCSectionType) {
    TLMineInfoVCSectionTypeBase,
    TLMineInfoVCSectionTypeMore,
};

@interface TLMineInfoViewController ()<TZImagePickerControllerDelegate>

@end

@implementation TLMineInfoViewController

- (void)loadView
{
    [super loadView];
    [self setTitle:LOCSTR(@"个人信息")];
    [self.view setBackgroundColor:[UIColor colorGrayBG]];
    
    [self loadMineInfoUI];
}

#pragma mark - # UI
- (void)loadMineInfoUI
{
    @weakify(self);
    self.clear();
    
    TLUser *userInfo = [TLUserHelper sharedHelper].user;
    
    {
        NSInteger sectionTag = TLMineInfoVCSectionTypeBase;
        self.addSection(sectionTag).sectionInsets(UIEdgeInsetsMake(15, 0, 0, 0));
        
        // 头像
        TLSettingItem *avatar = TLCreateSettingItem(@"头像");
        avatar.rightImageURL = userInfo.avatarURL;
        self.addCell([TLMineInfoAvatarCell class]).toSection(sectionTag).withDataModel(avatar).selectedAction(^ (id data) {
            @strongify(self)
            [self selectAvatarImage];
        });
        
        // 名字
        TLSettingItem *nikename = TLCreateSettingItem(@"名字");
        nikename.subTitle = userInfo.nikeName.length > 0 ? userInfo.nikeName : @"未设置";
        self.addCell(CELL_ST_ITEM_NORMAL).toSection(sectionTag).withDataModel(nikename).selectedAction(^ (id data) {
            
        });
        
        // 微信号
        TLSettingItem *wechatId = TLCreateSettingItem(@"微信号");
        wechatId.showDisclosureIndicator = userInfo.username.length == 0;
        wechatId.subTitle = userInfo.username.length > 0 ? userInfo.username : @"未设置";
        self.addCell(CELL_ST_ITEM_NORMAL).toSection(sectionTag).withDataModel(wechatId).selectedAction(^ (id data) {
            
        });
        
        // 二维码
        TLSettingItem *qrCode = TLCreateSettingItem(@"我的二维码");
        qrCode.rightImagePath = @"mine_cell_myQR";
        self.addCell(CELL_ST_ITEM_NORMAL).toSection(sectionTag).withDataModel(qrCode).selectedAction(^ (id data) {
            @strongify(self);
            TLMyQRCodeViewController *myQRCodeVC = [[TLMyQRCodeViewController alloc] init];
            PushVC(myQRCodeVC);
        });
        
        // 更多
        self.addCell(CELL_ST_ITEM_NORMAL).toSection(sectionTag).withDataModel(TLCreateSettingItem(@"更多")).selectedAction(^ (id data) {
            
        });
    }
    
    {
        NSInteger sectionTag = TLMineInfoVCSectionTypeMore;
        self.addSection(sectionTag).sectionInsets(UIEdgeInsetsMake(20, 0, 40, 0));
        
        // 我的地址
        self.addCell(CELL_ST_ITEM_NORMAL).toSection(sectionTag).withDataModel(TLCreateSettingItem(@"我的地址")).selectedAction(^ (id data) {
            
        });
        
        // 我的发票抬头
        self.addCell(CELL_ST_ITEM_NORMAL).toSection(sectionTag).withDataModel(TLCreateSettingItem(@"我的发票抬头")).selectedAction(^ (id data) {
            
        });
    }
    
    [self reloadView];
}

- (void)selectAvatarImage {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];

    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    @weakify(self)
    TZImagePickerController *imagePicker = [[TZImagePickerController alloc] initCropTypeWithAsset:assets.firstObject photo:photos.firstObject completion:^(UIImage *cropImage, id asset){
        @strongify(self)
        NSData *imageData = [cropImage compress];
        NSString *imageName = [NSString stringWithFormat:@"%lf.jpg", [NSDate date].timeIntervalSince1970];
        NSString *imagePath = [NSFileManager pathUserAvatar:imageName];
        [[NSFileManager defaultManager] createFileAtPath:imagePath contents:imageData attributes:nil];
        [self avatarImageUpload:imagePath];
    }];
    imagePicker.cropRect = CGRectMake(SCREEN_WIDTH/2 - 100, SCREEN_HEIGHT/2 - 100, 200, 200);
    imagePicker.scaleAspectFillCrop = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)avatarImageUpload:(NSString *)imagePath {
    NSString *url = @"http://192.168.2.100:8888/file/upload";
    TLUploadRequest *request = [[TLUploadRequest alloc]initWithMethod:TLRequestMethodPOST url:url parameters:nil];
    request.dataPath = imagePath;
    @weakify(self)
    request.constructingBodyAction = ^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:[NSData dataWithContentsOfFile:imagePath] name:@"file" fileName:imagePath.lastPathComponent mimeType: @"image/jpeg"];
    };
    [request startRequestWithSuccessAction:^(TLResponse *response) {
        @strongify(self)
        DDLogDebug(@"%@", response.responseString);
        NSDictionary *resObj = response.responseObject;
        BOOL isOK = [resObj[@"isok"] boolValue];
        if (isOK) {
            NSString *url = resObj[@"data"];
            [TLUserHelper sharedHelper].user.avatarPath = imagePath;
            [self updateUserAvatar:url];
        }
    } failureAction:^(TLResponse *response) {
        DDLogError(@"%@", response.error);
    }];
}

- (void)updateUserAvatar:(NSString *)avatarURL {

    @weakify(self)
    NSString *url = [HOST_URL stringByAppendingFormat:@"user/%@", [TLUserHelper sharedHelper].userID];
    NSDictionary *params = @{@"avatar" : avatarURL};
    [TLNetworking putUrl:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        @strongify(self)
        NSDictionary *json = [responseObject mj_JSONObject];
        BOOL isOK = [json[@"isok"] boolValue];
        if (isOK) {
            NSDictionary *data = json[@"data"];
            TLUser *user = [TLUser mj_objectWithKeyValues:data];
            [TLUserHelper sharedHelper].user.avatarURL = user.avatarURL;
            TLSettingItem *avatar = self.dataModel.atIndexPath([NSIndexPath indexPathForRow:0 inSection:0]);
            avatar.rightImageURL = user.avatarURL;
        }
        else {
            NSString *errorMsg = json[@"message"];
            [TLToast showErrorToast:errorMsg];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [TLToast showErrorToast:@"网络请求失败"];
    }];
}

@end
