//
//  BottomInfoView.m
//  MultiRoutePlan
//
//  Created by AutoNavi on 11/3/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import "BottomInfoView.h"

@interface BottomInfoView ()<RouteInfoViewDelegate>

@property (nonatomic, strong) NSMutableArray <RouteInfoView *> *allInfoViews;
@property (nonatomic, strong) UILabel *trafficLightLabel;
@property (nonatomic, strong) UIButton *startNaviButton;

@property (nonatomic, assign) NSInteger selectedRouteID;

@end

@implementation BottomInfoView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.allInfoViews = [[NSMutableArray alloc] init];
        
        [self buildBottomInfoView];
    }
    return self;
}

- (void)buildBottomInfoView
{
    self.backgroundColor = [UIColor lightGrayColor];
    
    self.trafficLightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth(self.bounds), 25)];
    [self.trafficLightLabel setBackgroundColor:[UIColor clearColor]];
    [self.trafficLightLabel setTextColor:[UIColor blackColor]];
    [self.trafficLightLabel setFont:[UIFont systemFontOfSize:14]];
    [self.trafficLightLabel setAdjustsFontSizeToFitWidth:YES];
    [self.trafficLightLabel setTextAlignment:NSTextAlignmentCenter];
    [self.trafficLightLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    
    self.startNaviButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.startNaviButton setFrame:CGRectMake(10, 125, CGRectGetWidth(self.bounds) - 20, 40)];
    [self.startNaviButton setTitle:@"开始导航" forState:UIControlStateNormal];
    [self.startNaviButton.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [self.startNaviButton setBackgroundColor:[UIColor colorWithRed:26/255.0 green:166/255.0 blue:239/255.0 alpha:1]];
    [self.startNaviButton addTarget:self action:@selector(startNaviButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.trafficLightLabel];
    [self addSubview:self.startNaviButton];
}

#pragma mark - Interface

- (void)setAllRouteInfo:(NSArray<RouteInfoViewModel *> *)allRouteInfo
{
    if (allRouteInfo == nil)
    {
        return;
    }
    
    _allRouteInfo = allRouteInfo;
    
    [self.allInfoViews enumerateObjectsUsingBlock:^(RouteInfoView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.allInfoViews removeAllObjects];
    
    int count = (int)_allRouteInfo.count;
    double singleWidth = CGRectGetWidth(self.bounds) / count;
    for (int i = 0; i < count; i++)
    {
        RouteInfoView *aView = [[RouteInfoView alloc] initWithFrame:CGRectMake(i*singleWidth, 0, singleWidth, 100)];
        aView.delegate = self;
        aView.routeInfo = [_allRouteInfo objectAtIndex:i];
        
        [self addSubview:aView];
        [self.allInfoViews addObject:aView];
    }
}

- (void)selecteNaviRouteWithRouteID:(NSInteger)routeID
{
    if (routeID < 0)
    {
        return;
    }
    
    for (RouteInfoView *aView in self.allInfoViews)
    {
        if (aView.routeInfo.routeID == self.selectedRouteID)
        {
            aView.selected = NO;
        }
        
        if (aView.routeInfo.routeID == routeID)
        {
            aView.selected = YES;
            [self.trafficLightLabel setText:[NSString stringWithFormat:@"红绿灯%d个", (int)aView.routeInfo.trafficLightCount]];
        }
    }
    
    self.selectedRouteID = routeID;
}

#pragma mark - Actions

- (void)startNaviButtonAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bottomInfoViewStartNaviWithRouteID:)])
    {
        [self.delegate bottomInfoViewStartNaviWithRouteID:self.selectedRouteID];
    }
}

- (void)routeInfoViewClickedWithRouteID:(NSInteger)routeID
{
    [self selecteNaviRouteWithRouteID:routeID];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(bottomInfoViewSelectedRouteWithRouteID:)])
    {
        [self.delegate bottomInfoViewSelectedRouteWithRouteID:self.selectedRouteID];
    }
}

@end
