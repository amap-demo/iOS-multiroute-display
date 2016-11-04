//
//  DriveNaviViewController.h
//  AMapNaviKit
//
//  Created by 刘博 on 16/3/8.
//  Copyright © 2016年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

@protocol DriveNaviViewControllerDelegate;

@interface DriveNaviViewController : UIViewController

@property (nonatomic, weak) id <DriveNaviViewControllerDelegate> delegate;

@property (nonatomic, strong) AMapNaviDriveView *driveView;

@end

@protocol DriveNaviViewControllerDelegate <NSObject>

- (void)driveNaviViewCloseButtonClicked;

@end
