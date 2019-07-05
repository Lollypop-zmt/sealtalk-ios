//
//  RCDSettingsTableViewController.m
//  RCloudMessage
//
//  Created by Liv on 14/11/20.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCDSettingsTableViewController.h"
#import "RCDBaseSettingTableViewCell.h"
#import "RCDChangePasswordViewController.h"
#import "RCDLoginViewController.h"
#import "RCDMessageNotifySettingTableViewController.h"
#import "RCDPrivacyTableViewController.h"
#import "RCDPushSettingViewController.h"
#import "RCDUIBarButtonItem.h"
#import "UIColor+RCColor.h"
#import "RCDLoginManager.h"
#import <RongIMKit/RongIMKit.h>
#import "RCDCommonString.h"

@interface RCDSettingsTableViewController () <UIAlertViewDelegate>

@end

@implementation RCDSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initUI];
}

- (void)viewDidLayoutSubviews {
    self.tableView.frame = self.view.frame;
}

#pragma mark - Table view Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger row = 0;
    if(0 == section) {
        row = 4;
    }else if (1 == section) {
        row = 1;
    }else if(2 == section) {
        row = 1;
    }
    return row;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(2 == indexPath.section) {
        return [self createQuitCell];
    }
    
    static NSString *reusableCellWithIdentifier = @"RCDBaseSettingTableViewCell";
    RCDBaseSettingTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier];
    if (cell == nil) {
        cell = [[RCDBaseSettingTableViewCell alloc] init];
    }
    [cell setCellStyle:DefaultStyle];
    NSString *text = @"";
    if(0 == indexPath.section) {
        if(0 == indexPath.row) {
            text = RCDLocalizedString(@"change_password");
        }else if(1 == indexPath.row) {
            text = RCDLocalizedString(@"privacy");
        }else if(2 == indexPath.row) {
            text = RCDLocalizedString(@"new_message_notification");
        }else if (3 == indexPath.row) {
            text = RCDLocalizedString(@"push_setting");
        }
    }else {
        text = RCDLocalizedString(@"clear_cache");
    }
    cell.leftLabel.text = text;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(0 == indexPath.section) {
        if(0 == indexPath.row) {
            RCDChangePasswordViewController *vc = [[RCDChangePasswordViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }else if(1 == indexPath.row) {
            RCDPrivacyTableViewController *vc = [[RCDPrivacyTableViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }else if (2 == indexPath.row) {
            RCDMessageNotifySettingTableViewController *vc = [[RCDMessageNotifySettingTableViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }else if (3 == indexPath.row) {
            RCDPushSettingViewController *vc = [[RCDPushSettingViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }else if(1 == indexPath.section) {
        //清除缓存
        [self showAlert:RCDLocalizedString(@"clear_cache_alert") cancelBtnTitle:RCDLocalizedString(@"cancel") otherBtnTitle:RCDLocalizedString(@"confirm") tag:1011];
    }else if(2 == indexPath.section) {
        //退出登录
        [self showAlert:RCDLocalizedString(@"logout_alert") cancelBtnTitle:RCDLocalizedString(@"cancel") otherBtnTitle:RCDLocalizedString(@"confirm") tag:1010];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15.f;
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1 && alertView.tag == 1010) {
        [self logout];
    }

    if (buttonIndex == 1 && alertView.tag == 1011) {
        [self clearCache];
    }
}

//清理缓存
- (void)clearCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        //这里清除 Library/Caches 里的所有文件，融云的缓存文件及图片存放在 Library/Caches/RongCloud 下
        NSString *cachPath =
            [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:cachPath];

        for (NSString *p in files) {
            NSError *error;
            NSString *path = [cachPath stringByAppendingPathComponent:p];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            }
        }
        [self performSelectorOnMainThread:@selector(clearCacheSuccess) withObject:nil waitUntilDone:YES];
    });
}

- (void)clearCacheSuccess {
    [self showAlert:RCDLocalizedString(@"clear_cache_succrss") cancelBtnTitle:RCDLocalizedString(@"confirm") otherBtnTitle:nil tag:-1];
}

//退出登录
- (void)logout {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [DEFAULTS removeObjectForKey:RCDIMTokenKey];
    [DEFAULTS synchronize];

    [RCDLoginManager logout:^(BOOL success) {
    }];

    RCDLoginViewController *loginVC = [[RCDLoginViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.view.window.rootViewController = navi;
    [[RCIM sharedRCIM] logout];
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.cn.rongcloud.im.share"];
    [userDefaults removeObjectForKey:RCDCookieKey];
    [userDefaults synchronize];
}

- (void)showAlert:(NSString *)message cancelBtnTitle:(NSString *)cBtnTitle otherBtnTitle:(NSString *)oBtnTitle tag:(int)tag {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:cBtnTitle otherButtonTitles:oBtnTitle, nil];
    if(tag > 0){
        alertView.tag = tag;
    }
    [alertView show];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (UITableViewCell *)createQuitCell {
    UITableViewCell *quitCell = [[UITableViewCell alloc] init];
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor colorWithHexString:@"000000" alpha:1.0];
    label.text = RCDLocalizedString(@"logout");
    label.translatesAutoresizingMaskIntoConstraints = NO;
    quitCell.contentView.layer.borderWidth = 0.5;
    quitCell.contentView.layer.borderColor = [[UIColor colorWithHexString:@"dfdfdf" alpha:1.0] CGColor];

    [quitCell setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 1000)];
    [quitCell.contentView addSubview:label];
    [quitCell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:quitCell.contentView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1
                                                                      constant:0]];

    [quitCell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:quitCell.contentView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1
                                                                      constant:0]];
    return quitCell;
}

- (void)initUI {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor colorWithHexString:@"f0f0f6" alpha:1.f];
    
    self.navigationItem.title = RCDLocalizedString(@"account_setting");
    RCDUIBarButtonItem *leftBtn =
    [[RCDUIBarButtonItem alloc] initWithLeftBarButton:RCDLocalizedString(@"me")
                                               target:self action:@selector(clickBackBtn:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

@end