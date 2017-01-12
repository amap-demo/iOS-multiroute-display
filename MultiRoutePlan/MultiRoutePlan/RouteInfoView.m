//
//  RouteInfoView.m
//  MultiRoutePlan
//
//  Created by AutoNavi on 11/3/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import "RouteInfoView.h"

#define kSelectedColor      [UIColor colorWithRed:26/255.0 green:166/255.0 blue:239/255.0 alpha:1]
#define kDeselectedColor    [UIColor darkGrayColor]

@implementation RouteInfoViewModel
@end

@interface RouteInfoView ()

@property (nonatomic, strong) UIView *tipView;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *lengthLabel;

@property (nonatomic, strong) UIButton *coverButton;

@end

@implementation RouteInfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self buildInfoView];
    }
    return self;
}

- (void)buildInfoView
{
    self.backgroundColor = [UIColor whiteColor];
    
    self.tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 4)];
    
    self.tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.bounds), 25)];
    [self.tagLabel setBackgroundColor:[UIColor clearColor]];
    [self.tagLabel setTextColor:kDeselectedColor];
    [self.tagLabel setFont:[UIFont systemFontOfSize:16]];
    [self.tagLabel setAdjustsFontSizeToFitWidth:YES];
    [self.tagLabel setTextAlignment:NSTextAlignmentCenter];
    [self.tagLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, CGRectGetWidth(self.bounds), 40)];
    [self.timeLabel setBackgroundColor:[UIColor clearColor]];
    [self.timeLabel setTextColor:[UIColor blackColor]];
    [self.timeLabel setFont:[UIFont boldSystemFontOfSize:22]];
    [self.timeLabel setAdjustsFontSizeToFitWidth:YES];
    [self.timeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.timeLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    
    self.lengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, CGRectGetWidth(self.bounds), 25)];
    [self.lengthLabel setBackgroundColor:[UIColor clearColor]];
    [self.lengthLabel setTextColor:kDeselectedColor];
    [self.lengthLabel setFont:[UIFont systemFontOfSize:16]];
    [self.lengthLabel setAdjustsFontSizeToFitWidth:YES];
    [self.lengthLabel setTextAlignment:NSTextAlignmentCenter];
    [self.lengthLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    
    self.coverButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.coverButton setBackgroundColor:[UIColor clearColor]];
    [self.coverButton setFrame:self.bounds];
    [self.coverButton addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.coverButton setAccessibilityIdentifier:@"RouteInfoViewButton"];
    
    [self addSubview:self.tipView];
    [self addSubview:self.tagLabel];
    [self addSubview:self.timeLabel];
    [self addSubview:self.lengthLabel];
    [self addSubview:self.coverButton];
}

- (void)setRouteInfo:(RouteInfoViewModel *)routeInfo
{
    if (routeInfo == nil)
    {
        return;
    }
    
    _routeInfo = routeInfo;
    
    [self.tagLabel setText:_routeInfo.routeTag];
    [self.timeLabel setText:[self normalizedRemainTime:_routeInfo.routeTime]];
    [self.lengthLabel setText:[self normalizedRemainDistance:_routeInfo.routeLength]];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    if (_selected)
    {
        [self.tipView setBackgroundColor:kSelectedColor];
        [self.tagLabel setTextColor:kSelectedColor];
        [self.timeLabel setTextColor:kSelectedColor];
        [self.lengthLabel setTextColor:kSelectedColor];
    }
    else
    {
        [self.tipView setBackgroundColor:[UIColor clearColor]];
        [self.tagLabel setTextColor:kDeselectedColor];
        [self.timeLabel setTextColor:[UIColor blackColor]];
        [self.lengthLabel setTextColor:kDeselectedColor];
    }
}

- (void)buttonAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(routeInfoViewClickedWithRouteID:)])
    {
        [self.delegate routeInfoViewClickedWithRouteID:_routeInfo.routeID];
    }
}

- (nullable NSString *)normalizedRemainDistance:(NSInteger)remainDistance
{
    if (remainDistance < 0)
    {
        return nil;
    }
    
    if (remainDistance >= 1000)
    {
        CGFloat kiloMeter = remainDistance / 1000.0;
        
        if (remainDistance % 1000 >= 100)
        {
            kiloMeter -= 0.05f;
            return [NSString stringWithFormat:@"%.1f公里", kiloMeter];
        }
        else
        {
            return [NSString stringWithFormat:@"%.0f公里", kiloMeter];
        }
    }
    else
    {
        return [NSString stringWithFormat:@"%ld米", (long)remainDistance];
    }
}

- (nullable NSString *)normalizedRemainTime:(NSInteger)remainTime
{
    if (remainTime < 0)
    {
        return nil;
    }
    
    if (remainTime < 60)
    {
        return [NSString stringWithFormat:@"< 1分钟"];
    }
    else if (remainTime >= 60 && remainTime < 60*60)
    {
        return [NSString stringWithFormat:@"%ld分钟", (long)remainTime/60];
    }
    else
    {
        NSInteger hours = remainTime / 60 / 60;
        NSInteger minute = remainTime / 60 % 60;
        if (minute == 0)
        {
            return [NSString stringWithFormat:@"%ld小时", (long)hours];
        }
        else
        {
            return [NSString stringWithFormat:@"%ld小时%ld分钟", (long)hours, (long)minute];
        }
    }
}

@end
