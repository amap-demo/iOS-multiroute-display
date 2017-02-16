本工程为基于高德地图iOS 3D地图SDK和导航SDK进行封装，实现了按照交通路况展示多路径的功能。
## 前述 ##
- [高德官网申请Key](http://lbs.amap.com/dev/#/).
- 阅读[开发指南](http://lbs.amap.com/api/ios-navi-sdk/summary/).
- 工程基于iOS 3D地图SDK和导航SDK实现

## 功能描述 ##
通过导航SDK进行多路径规划，并按照交通路况进行展示。

## 核心类/接口 ##
| 类    | 接口  | 说明   | 版本  |
| -----|:-----:|:-----:|:-----:|
| AMapNaviDriveManager	| - (BOOL)selectNaviRouteWithRouteID:(NSInteger)routeID; | 选择导航路径 | v2.0.0 |
| AMapNaviDriveManager	| - (nullable NSArray<AMapNaviTrafficStatus *> *)getTrafficStatusesWithStartPosition:(int)startPosition distance:(int)distance; | 获取路径的交通状况信息 | v2.0.0 |

## 核心难点 ##

`Objective-C`
```
/* 根据路近况信息绘制带路况信息的polyline. */
- (void)addRoutePolylineWithRouteID:(NSInteger)routeID
{
    //必须选中路线后，才可以通过driveManager获取实时交通路况
    if (![self.driveManager selectNaviRouteWithRouteID:routeID])
    {
        return;
    }
    
    //获取路线坐标串
    NSArray <AMapNaviPoint *> *oriCoordinateArray = [self.driveManager.naviRoute.routeCoordinates copy];

    //获取路径的交通状况信息
    NSArray <AMapNaviTrafficStatus *> *trafficStatus = [self.driveManager getTrafficStatusesWithStartPosition:0 distance:(int)self.driveManager.naviRoute.routeLength];
    
    //创建带路况信息的polyline，具体代码见Demo
    ......
    
    [self.mapView addOverlay:polyline level:MAOverlayLevelAboveLabels];
}

/* 选择对应的polyline，改变polyline的颜色. */
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
```

`Swift`
```
/* 根据路近况信息绘制带路况信息的polyline. */
func addRoutePolylineWithRouteID(_ routeID: Int) {
    //必须选中路线后，才可以通过driveManager获取实时交通路况
    if !driveManager.selectNaviRoute(withRouteID: routeID) {
        return
    }
    
    guard let aRoute = driveManager.naviRoute else {
        return
    }
    
    //获取路线坐标串
    guard let oriCoordinateArray = aRoute.routeCoordinates else {
        return
    }
    guard let trafficStatus = driveManager.getTrafficStatuses(withStartPosition: 0, distance: Int32(aRoute.routeLength)) else {
        return
    }
    
    //创建带路况信息的polyline，具体代码见Demo
    ......
    
    mapView.add(polyline, level: .aboveLabels)
}

/* 选择对应的polyline，改变polyline的颜色. */
func selecteOverlayWithRouteID(routeID: Int) {
    guard let allOverlays = mapView.overlays else {
        return
    }
    
    for (index, aOverlay) in allOverlays.enumerated() {
        
        if let selectableOverlay = aOverlay as? SelectableTrafficOverlay {
            
            /* 获取overlay对应的renderer. */
            let overlayRenderer = mapView.renderer(for: selectableOverlay) as! MAMultiColoredPolylineRenderer
            
            if selectableOverlay.routeID == routeID {
                
                /* 设置选中状态. */
                selectableOverlay.selected = true
                
                /* 修改renderer选中颜色. */
                var strokeColors = Array<UIColor>()
                for aColor in selectableOverlay.polylineStrokeColors {
                    strokeColors.append(aColor.withAlphaComponent(1.0))
                }
                selectableOverlay.polylineStrokeColors = strokeColors
                overlayRenderer.strokeColors = selectableOverlay.polylineStrokeColors
                
                /* 修改overlay覆盖的顺序. */
                mapView.exchangeOverlay(at: UInt(index), withOverlayAt: UInt(mapView.overlays.count - 1))
                mapView.showOverlays([aOverlay], animated: true)
            }
            else {
                /* 设置选中状态. */
                selectableOverlay.selected = false
                
                /* 修改renderer选中颜色. */
                var strokeColors = Array<UIColor>()
                for aColor in selectableOverlay.polylineStrokeColors {
                    strokeColors.append(aColor.withAlphaComponent(0.25))
                }
                selectableOverlay.polylineStrokeColors = strokeColors
                overlayRenderer.strokeColors = selectableOverlay.polylineStrokeColors
            }
            
            overlayRenderer.glRender()
        }
    }
}
```
