//
//  BottomInfoView.h
//  MultiRoutePlan
//
//  Created by AutoNavi on 11/3/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RouteInfoView.h"

@protocol BottomInfoViewDelegate <NSObject>

- (void)bottomInfoViewSelectedRouteWithRouteID:(NSInteger)routeID;
- (void)bottomInfoViewStartNaviWithRouteID:(NSInteger)routeID;

@end

@interface BottomInfoView : UIView

@property (nonatomic, weak) id<BottomInfoViewDelegate> delegate;

@property (nonatomic, strong) NSArray <RouteInfoViewModel *> *allRouteInfo;

- (void)selecteNaviRouteWithRouteID:(NSInteger)routeID;

@end
