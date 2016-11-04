//
//  RouteInfoView.h
//  MultiRoutePlan
//
//  Created by AutoNavi on 11/3/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RouteInfoViewModel : NSObject

@property (nonatomic, assign) NSInteger routeID;

@property (nonatomic, strong) NSString *routeTag;
@property (nonatomic, assign) NSInteger routeTime;
@property (nonatomic, assign) NSInteger routeLength;
@property (nonatomic, assign) NSInteger trafficLightCount;

@end

@protocol RouteInfoViewDelegate <NSObject>

- (void)routeInfoViewClickedWithRouteID:(NSInteger)routeID;

@end

@interface RouteInfoView : UIView

@property (nonatomic, weak) id<RouteInfoViewDelegate> delegate;

@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, strong) RouteInfoViewModel *routeInfo;

@end
