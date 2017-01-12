//
//  MultiRoutePlanViewController.m
//  AMapNaviKit
//
//  Created by 刘博 on 16/3/7.
//  Copyright © 2016年 AutoNavi. All rights reserved.
//

#import "MultiRoutePlanViewController.h"

#import "SpeechSynthesizer.h"
#import "NaviPointAnnotation.h"
#import "SelectableTrafficOverlay.h"
#import "DriveNaviViewController.h"
#import "PreferenceView.h"
#import "BottomInfoView.h"

#define kRoutePlanInfoViewHeight    75.f
#define kBottomInfoViewHeight       170.f

@interface MultiRoutePlanViewController ()<MAMapViewDelegate, AMapNaviDriveManagerDelegate, DriveNaviViewControllerDelegate, BottomInfoViewDelegate>

@property (nonatomic, strong) AMapNaviPoint *startPoint;
@property (nonatomic, strong) AMapNaviPoint *endPoint;

@property (nonatomic, strong) PreferenceView *preferenceView;
@property (nonatomic, strong) BottomInfoView *bottomInfoView;

@property (nonatomic, assign) BOOL needRoutePlan;

@end

@implementation MultiRoutePlanViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setTitle:@"多路径规划"];
    
    [self initProperties];
    
    [self initMapView];
    
    [self initDriveManager];
    
    [self configSubViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self initAnnotations];
    
    //只在第一次进入后进行路径规划
    if (self.needRoutePlan)
    {
        [self routePlanAction:nil];
    }
}

#pragma mark - Initalization

- (void)initProperties
{
    //为了方便展示驾车多路径规划，选择了固定的起终点
    self.startPoint = [AMapNaviPoint locationWithLatitude:39.993135 longitude:116.474175];
    self.endPoint   = [AMapNaviPoint locationWithLatitude:39.908791 longitude:116.321257];
    
    self.needRoutePlan = YES;
}

- (void)initMapView
{
    if (self.mapView == nil)
    {
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, kRoutePlanInfoViewHeight,
                                                                   self.view.bounds.size.width,
                                                                   self.view.bounds.size.height - kRoutePlanInfoViewHeight - kBottomInfoViewHeight)];
        [self.mapView setDelegate:self];
        
        [self.view addSubview:self.mapView];
    }
}

- (void)initDriveManager
{
    if (self.driveManager == nil)
    {
        self.driveManager = [[AMapNaviDriveManager alloc] init];
        [self.driveManager setDelegate:self];
        
        [self.driveManager setAllowsBackgroundLocationUpdates:YES];
        [self.driveManager setPausesLocationUpdatesAutomatically:NO];
    }
}

- (void)initAnnotations
{
    NaviPointAnnotation *beginAnnotation = [[NaviPointAnnotation alloc] init];
    [beginAnnotation setCoordinate:CLLocationCoordinate2DMake(self.startPoint.latitude, self.startPoint.longitude)];
    beginAnnotation.title = @"起始点";
    beginAnnotation.navPointType = NaviPointAnnotationStart;
    
    [self.mapView addAnnotation:beginAnnotation];
    
    NaviPointAnnotation *endAnnotation = [[NaviPointAnnotation alloc] init];
    [endAnnotation setCoordinate:CLLocationCoordinate2DMake(self.endPoint.latitude, self.endPoint.longitude)];
    endAnnotation.title = @"终点";
    endAnnotation.navPointType = NaviPointAnnotationEnd;
    
    [self.mapView addAnnotation:endAnnotation];
}

#pragma mark - Button Action

- (void)routePlanAction:(id)sender
{
    //进行多路径规划
    [self.driveManager calculateDriveRouteWithStartPoints:@[self.startPoint]
                                                endPoints:@[self.endPoint]
                                                wayPoints:nil
                                          drivingStrategy:[self.preferenceView strategyWithIsMultiple:YES]];
}

#pragma mark - Handle Navi Routes

- (void)showNaviRoutes
{
    if ([self.driveManager.naviRoutes count] <= 0)
    {
        return;
    }
    
    [self.mapView removeOverlays:self.mapView.overlays];
    NSMutableArray *allInfoModels = [[NSMutableArray alloc] init];
    NSDictionary *allTags = [self createRotueTagString];
    
    for (NSNumber *aRouteID in [self.driveManager.naviRoutes allKeys])
    {
        AMapNaviRoute *aRoute = [[self.driveManager naviRoutes] objectForKey:aRouteID];
        
        //添加带实时路况的Polyline
        [self addRoutePolylineWithRouteID:[aRouteID integerValue]];
        
        //创建RouteInfoViewModel
        RouteInfoViewModel *aInfoModel = [[RouteInfoViewModel alloc] init];
        [aInfoModel setRouteID:[aRouteID intValue]];
        [aInfoModel setRouteTag:[allTags objectForKey:aRouteID]];
        [aInfoModel setRouteTime:aRoute.routeTime];
        [aInfoModel setRouteLength:aRoute.routeLength];
        [aInfoModel setTrafficLightCount:aRoute.routeTrafficLightCount];
        
        [allInfoModels addObject:aInfoModel];
    }
    [self.bottomInfoView setAllRouteInfo:allInfoModels];
    
    //默认选择第一条路线
    NSInteger selectedRouteID = [[allInfoModels firstObject] routeID];
    [self selectNaviRouteWithID:selectedRouteID];
    [self.bottomInfoView selecteNaviRouteWithRouteID:selectedRouteID];
}

- (void)selectNaviRouteWithID:(NSInteger)routeID
{
    //在开始导航前进行路径选择
    if ([self.driveManager selectNaviRouteWithRouteID:routeID])
    {
        [self selecteOverlayWithRouteID:routeID];
    }
    else
    {
        NSLog(@"路径选择失败!");
    }
}

- (void)selecteOverlayWithRouteID:(NSInteger)routeID
{
    [self.mapView.overlays enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<MAOverlay> overlay, NSUInteger idx, BOOL *stop)
     {
         if ([overlay isKindOfClass:[SelectableTrafficOverlay class]])
         {
             SelectableTrafficOverlay *selectableOverlay = overlay;
             
             /* 获取overlay对应的renderer. */
             MAMultiColoredPolylineRenderer * overlayRenderer = (MAMultiColoredPolylineRenderer *)[self.mapView rendererForOverlay:selectableOverlay];
             
             if (selectableOverlay.routeID == routeID)
             {
                 /* 设置选中状态. */
                 selectableOverlay.selected = YES;
                 
                 /* 修改renderer选中颜色. */
                 NSMutableArray *strokeColors = [[NSMutableArray alloc] init];
                 for (UIColor *aColor in selectableOverlay.polylineStrokeColors)
                 {
                     [strokeColors addObject:[aColor colorWithAlphaComponent:1]];
                 }
                 selectableOverlay.polylineStrokeColors = strokeColors;
                 overlayRenderer.strokeColors = selectableOverlay.polylineStrokeColors;
                 
                 /* 修改overlay覆盖的顺序. */
                 [self.mapView exchangeOverlayAtIndex:idx withOverlayAtIndex:self.mapView.overlays.count - 1];
                 [self.mapView showOverlays:@[overlay] animated:YES];
             }
             else
             {
                 /* 设置选中状态. */
                 selectableOverlay.selected = NO;
                 
                 /* 修改renderer选中颜色. */
                 NSMutableArray *strokeColors = [[NSMutableArray alloc] init];
                 for (UIColor *aColor in selectableOverlay.polylineStrokeColors)
                 {
                     [strokeColors addObject:[aColor colorWithAlphaComponent:0.25]];
                 }
                 selectableOverlay.polylineStrokeColors = strokeColors;
                 overlayRenderer.strokeColors = selectableOverlay.polylineStrokeColors;
             }
             
             [overlayRenderer glRender];
         }
     }];
}

#pragma mark - Handle Navi Route Info

/* 创建路线标签 */
- (NSDictionary *)createRotueTagString
{
    NSArray <NSNumber *> *allRouteIDs = [self.driveManager.naviRoutes allKeys];
    AMapNaviDrivingStrategy strategy = [self.preferenceView strategyWithIsMultiple:YES];
    
    NSInteger minTime = NSIntegerMax;
    NSInteger minLength = NSIntegerMax;
    NSInteger minTrafficLightCount = NSIntegerMax;
    NSInteger minCost = NSIntegerMax;
    
    for (AMapNaviRoute *aRoute in [self.driveManager.naviRoutes allValues])
    {
        if (aRoute.routeTime < minTime) minTime = aRoute.routeTime;
        
        if (aRoute.routeLength < minLength) minLength = aRoute.routeLength;
        
        if (aRoute.routeTrafficLightCount < minTrafficLightCount) minTrafficLightCount = aRoute.routeTrafficLightCount;
        
        if (aRoute.routeTollCost < minCost) minCost = aRoute.routeTollCost;
    }
    
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < allRouteIDs.count; i++)
    {
        NSNumber *aRouteID = [allRouteIDs objectAtIndex:i];
        AMapNaviRoute *aRoute = [[self.driveManager naviRoutes] objectForKey:aRouteID];
        
        NSString *resultTag = [NSMutableString stringWithFormat:@"方案%d", i+1];
        if (aRoute.routeTrafficLightCount <= minTrafficLightCount)
        {
            resultTag = @"红绿灯少";
        }
        if (aRoute.routeTollCost <= minCost)
        {
            resultTag = @"收费较少";
        }
        if ((int)(aRoute.routeLength / 100) <= (int)(minLength / 100))
        {
            resultTag = @"距离最短";
        }
        if (aRoute.routeTime <= minTime)
        {
            resultTag = @"时间最短";
        }
        
        if (0 == i && AMapNaviDrivingStrategyMultipleAvoidCongestion == strategy)
        {
            resultTag = @"躲避拥堵";
        }
        if (0 == i && AMapNaviDrivingStrategyMultipleAvoidHighway == strategy)
        {
            resultTag = @"不走高速";
        }
        if (0 == i && AMapNaviDrivingStrategyMultipleAvoidCost == strategy)
        {
            resultTag = @"避免收费";
        }
        if (0 == i && [resultTag hasPrefix:@"方案"])
        {
            resultTag = @"推荐";
        }
        
        [resultDic setObject:resultTag forKey:aRouteID];
    }
    
    return resultDic;
}

- (double)calcDistanceBetweenPoint:(AMapNaviPoint *)pointA andPoint:(AMapNaviPoint *)pointB
{
    MAMapPoint mapPointA = MAMapPointForCoordinate(CLLocationCoordinate2DMake(pointA.latitude, pointA.longitude));
    MAMapPoint mapPointB = MAMapPointForCoordinate(CLLocationCoordinate2DMake(pointB.latitude, pointB.longitude));
    
    return MAMetersBetweenMapPoints(mapPointA, mapPointB);
}

- (AMapNaviPoint *)calcPointWithStartPoint:(AMapNaviPoint *)start endPoint:(AMapNaviPoint *)end rate:(double)rate
{
    if (rate > 1.0 || rate < 0)
    {
        return nil;
    }
    
    MAMapPoint from = MAMapPointForCoordinate(CLLocationCoordinate2DMake(start.latitude, start.longitude));
    MAMapPoint to = MAMapPointForCoordinate(CLLocationCoordinate2DMake(end.latitude, end.longitude));
    
    double latitudeDelta = (to.y - from.y) * rate;
    double longitudeDelta = (to.x - from.x) * rate;
    
    CLLocationCoordinate2D coordinate = MACoordinateForMapPoint(MAMapPointMake(from.x + longitudeDelta, from.y + latitudeDelta));
    
    return [AMapNaviPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
}

- (UIColor *)defaultColorForStatus:(AMapNaviRouteStatus)status
{
    switch (status) {
        case AMapNaviRouteStatusSmooth:     //1-通畅-green
            return [UIColor colorWithRed:65/255.0 green:223/255.0 blue:16/255.0 alpha:1];
        case AMapNaviRouteStatusSlow:       //2-缓行-yellow
            return [UIColor yellowColor];
        case AMapNaviRouteStatusJam:        //3-阻塞-red
            return [UIColor redColor];
        case AMapNaviRouteStatusSeriousJam: //4-严重阻塞-brown
            return [UIColor colorWithRed:160/255.0 green:8/255.0 blue:8/255.0 alpha:1];
        default:                            //0-未知状态-blue
            return [UIColor colorWithRed:26/255.0 green:166/255.0 blue:239/255.0 alpha:1];
    }
}

- (void)addRoutePolylineWithRouteID:(NSInteger)routeID
{
    //必须选中路线后，才可以通过driveManager获取实时交通路况
    if (![self.driveManager selectNaviRouteWithRouteID:routeID])
    {
        return;
    }
    
    NSArray <AMapNaviPoint *> *oriCoordinateArray = [self.driveManager.naviRoute.routeCoordinates copy];
    NSArray <AMapNaviTrafficStatus *> *trafficStatus = [self.driveManager getTrafficStatusesWithStartPosition:0 distance:(int)self.driveManager.naviRoute.routeLength];
    
    NSMutableArray <AMapNaviPoint *> *resultCoords = [[NSMutableArray alloc] init];
    NSMutableArray <NSNumber *> *coordIndexes = [[NSMutableArray alloc] init];
    NSMutableArray <UIColor *> *strokeColors = [[NSMutableArray alloc] init];
    [resultCoords addObject:[oriCoordinateArray objectAtIndex:0]];
    
    //依次计算每个路况的长度对应的polyline点的index
    unsigned int i = 1;
    NSInteger sumLength = 0;
    NSInteger statusesIndex = 0;
    NSInteger curTrafficLength = [[trafficStatus firstObject] length];
    
    for ( ; i < [oriCoordinateArray count]; i++)
    {
        double segDis = [self calcDistanceBetweenPoint:[oriCoordinateArray objectAtIndex:i-1]
                                              andPoint:[oriCoordinateArray objectAtIndex:i]];
        
        //两点间插入路况改变的点
        if (sumLength + segDis >= curTrafficLength)
        {
            if (sumLength + segDis == curTrafficLength)
            {
                [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
            }
            else
            {
                double rate = (segDis==0 ? 0 : ((curTrafficLength - sumLength) / segDis));
                AMapNaviPoint *extrnPoint = [self calcPointWithStartPoint:[oriCoordinateArray objectAtIndex:i-1]
                                                                 endPoint:[oriCoordinateArray objectAtIndex:i]
                                                                     rate:MAX(MIN(rate, 1.0), 0)];
                if (extrnPoint)
                {
                    [resultCoords addObject:extrnPoint];
                    [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
                    [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                }
                else
                {
                    [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                    [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
                }
            }
            
            //添加对应的strokeColors
            [strokeColors addObject:[self defaultColorForStatus:[[trafficStatus objectAtIndex:statusesIndex] status]]];
            
            sumLength = sumLength + segDis - curTrafficLength;
            
            if (++statusesIndex >= [trafficStatus count])
            {
                break;
            }
            curTrafficLength = [[trafficStatus objectAtIndex:statusesIndex] length];
        }
        else
        {
            [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
            
            sumLength += segDis;
        }
    }
    
    //将最后一个点对齐到路径终点
    if (i < [oriCoordinateArray count])
    {
        while (i < [oriCoordinateArray count])
        {
            [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
            i++;
        }
        
        [coordIndexes removeLastObject];
        [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
    }
    else
    {
        while (((int)[coordIndexes count])-1 >= (int)[trafficStatus count])
        {
            [coordIndexes removeLastObject];
            [strokeColors removeLastObject];
        }
        
        [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
        //需要修改textureImages的最后一个与trafficStatus最后一个一致
        [strokeColors addObject:[self defaultColorForStatus:[[trafficStatus lastObject] status]]];
    }
    
    //添加Polyline
    NSInteger coordCount = [resultCoords count];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(coordCount * sizeof(CLLocationCoordinate2D));
    for (int k = 0; k < coordCount; k++)
    {
        AMapNaviPoint *aCoordinate = [resultCoords objectAtIndex:k];
        coordinates[k] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    //创建SelectableTrafficOverlay
    SelectableTrafficOverlay *polyline = [SelectableTrafficOverlay polylineWithCoordinates:coordinates count:coordCount drawStyleIndexes:coordIndexes];
    polyline.routeID = routeID;
    polyline.selected = NO;
    polyline.polylineWidth = 10;
    polyline.polylineStrokeColors = strokeColors;
    
    if (coordinates != NULL)
    {
        free(coordinates);
    }
    
    [self.mapView addOverlay:polyline level:MAOverlayLevelAboveLabels];
}

#pragma mark - SubViews

- (void)configSubViews
{
    self.preferenceView = [[PreferenceView alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.view.bounds), 30)];
    [self.view addSubview:self.preferenceView];
    
    UIButton *routeBtn = [self createToolButton];
    [routeBtn setFrame:CGRectMake((CGRectGetWidth(self.view.bounds)-80)/2.0, 40, 80, 30)];
    [routeBtn setTitle:@"路径规划" forState:UIControlStateNormal];
    [routeBtn addTarget:self action:@selector(routePlanAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:routeBtn];
    
    self.bottomInfoView = [[BottomInfoView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 64 - kBottomInfoViewHeight, CGRectGetWidth(self.view.bounds), kBottomInfoViewHeight)];
    self.bottomInfoView.delegate = self;
    [self.view addSubview:self.bottomInfoView];
    
    RouteInfoViewModel *aNilModel = [[RouteInfoViewModel alloc] init];
    aNilModel.routeTag = @"请在上方进行算路";
    [self.bottomInfoView setAllRouteInfo:@[aNilModel]];
}

- (UIButton *)createToolButton
{
    UIButton *toolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    toolBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    toolBtn.layer.borderWidth  = 0.5;
    toolBtn.layer.cornerRadius = 5;
    
    [toolBtn setBounds:CGRectMake(0, 0, 80, 30)];
    [toolBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    toolBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    
    return toolBtn;
}

#pragma mark - BottomInfoView Delegate

- (void)bottomInfoViewSelectedRouteWithRouteID:(NSInteger)routeID
{
    //选择对应的路线
    [self selectNaviRouteWithID:routeID];
}

- (void)bottomInfoViewStartNaviWithRouteID:(NSInteger)routeID
{
    DriveNaviViewController *driveVC = [[DriveNaviViewController alloc] init];
    [driveVC setDelegate:self];
    
    //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
    [self.driveManager addDataRepresentative:driveVC.driveView];
    
    [self.navigationController pushViewController:driveVC animated:NO];
    [self.driveManager startEmulatorNavi];
}

#pragma mark - AMapNaviDriveManager Delegate

- (void)driveManager:(AMapNaviDriveManager *)driveManager error:(NSError *)error
{
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    self.needRoutePlan = NO;
    [self showNaviRoutes];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
}

- (void)driveManagerNeedRecalculateRouteForYaw:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForYaw");
}

- (void)driveManagerNeedRecalculateRouteForTrafficJam:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForTrafficJam");
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onArrivedWayPoint:(int)wayPointIndex
{
    NSLog(@"onArrivedWayPoint:%d", wayPointIndex);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

- (void)driveManagerDidEndEmulatorNavi:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"didEndEmulatorNavi");
}

- (void)driveManagerOnArrivedDestination:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onArrivedDestination");
}

#pragma mark - DriveNaviView Delegate

- (void)driveNaviViewCloseButtonClicked
{
    //开始导航后不再允许选择路径，所以停止导航
    [self.driveManager stopNavi];
    
    //停止语音
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - MAMapView Delegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[NaviPointAnnotation class]])
    {
        static NSString *annotationIdentifier = @"NaviPointAnnotationIdentifier";
        
        MAPinAnnotationView *pointAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (pointAnnotationView == nil)
        {
            pointAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                                  reuseIdentifier:annotationIdentifier];
        }
        
        pointAnnotationView.animatesDrop   = NO;
        pointAnnotationView.canShowCallout = YES;
        pointAnnotationView.draggable      = NO;
        
        NaviPointAnnotation *navAnnotation = (NaviPointAnnotation *)annotation;
        
        if (navAnnotation.navPointType == NaviPointAnnotationStart)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorGreen];
        }
        else if (navAnnotation.navPointType == NaviPointAnnotationEnd)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorRed];
        }
        
        return pointAnnotationView;
    }
    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[SelectableTrafficOverlay class]])
    {
        SelectableTrafficOverlay *routeOverlay = (SelectableTrafficOverlay *)overlay;
        
        if (routeOverlay.polylineStrokeColors && routeOverlay.polylineStrokeColors.count > 0)
        {
            MAMultiColoredPolylineRenderer *polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:routeOverlay];
            
            polylineRenderer.lineWidth = routeOverlay.polylineWidth;
            polylineRenderer.lineJoinType = kMALineJoinRound;
            polylineRenderer.strokeColors = routeOverlay.polylineStrokeColors;
            polylineRenderer.gradient = NO;
            polylineRenderer.fillColor = [UIColor redColor];
            
            return polylineRenderer;
        }
    }
    
    return nil;
}

@end
