//
//  MultiRoutePlanViewController.swift
//  MultiRoutePlan
//
//  Created by liubo on 2017/1/9.
//  Copyright © 2017年 Amap. All rights reserved.
//

import UIKit

class MultiRoutePlanViewController: UIViewController, MAMapViewDelegate, AMapNaviDriveManagerDelegate, DriveNaviViewControllerDelegate, BottomInfoViewDelegate {
    
    let routePlanInfoViewHeight: CGFloat = 75.0
    let bottomInfoViewHeight: CGFloat = 170.0
    
    var mapView: MAMapView!
    var driveManager: AMapNaviDriveManager!
    
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.908791, longitude: 116.321257)!
    
    var needRoutePlan = true
    var preferenceView: PreferenceView!
    var bottomInfoView: BottomInfoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = "多路径规划-swift"
        
        initMapView()
        initDriveManager()
        
        configSubview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.isToolbarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initAnnotations()
        
        if needRoutePlan {
            routePlanAction(sender: nil)
        }
    }

    // MARK: - Initalization
    
    func initMapView() {
        mapView = MAMapView(frame: CGRect(x: 0, y: routePlanInfoViewHeight, width: view.bounds.width, height: view.bounds.height - routePlanInfoViewHeight - bottomInfoViewHeight))
        mapView.delegate = self
        
        view.addSubview(mapView)
    }
    
    func initDriveManager() {
        driveManager = AMapNaviDriveManager()
        driveManager.delegate = self
        
        driveManager.allowsBackgroundLocationUpdates = true
        driveManager.pausesLocationUpdatesAutomatically = false
    }
    
    func initAnnotations() {
        let beginAnnotation = NaviPointAnnotation()
        beginAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(startPoint.latitude), longitude: Double(startPoint.longitude))
        beginAnnotation.title = "起始点"
        beginAnnotation.naviPointType = .start
        
        mapView.addAnnotation(beginAnnotation)
        
        let endAnnotation = NaviPointAnnotation()
        endAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(endPoint.latitude), longitude: Double(endPoint.longitude))
        endAnnotation.title = "终点"
        endAnnotation.naviPointType = .end
        
        mapView.addAnnotation(endAnnotation)
    }
    
    //MARK: - Button Action
    
    func routePlanAction(sender: UIButton?) {
        //进行多路径规划
        driveManager.calculateDriveRoute(withStart: [startPoint],
                                         end: [endPoint],
                                         wayPoints: nil,
                                         drivingStrategy: preferenceView.strategy(withIsMultiple: true))
    }
    
    //MARK: - Handle Navi Routes
    
    func showNaviRoutes() {
        
        guard let allRoutes = driveManager.naviRoutes else {
            return
        }
        
        mapView.removeOverlays(mapView.overlays)
        var allInfoModels = Array<RouteInfoViewModel>()
        guard let allTags = createRouteTagString() else {
            return
        }
        
        for (aNumber, aRoute) in allRoutes {
            //添加带实时路况的Polyline
            addRoutePolylineWithRouteID(aNumber.intValue)
            
            //创建RouteInfoViewModel
            let aInfoModel = RouteInfoViewModel()
            aInfoModel.routeID = aNumber.intValue
            aInfoModel.routeTag = allTags[aNumber]
            aInfoModel.routeTime = aRoute.routeTime
            aInfoModel.routeLength = aRoute.routeLength
            aInfoModel.trafficLightCount = aRoute.routeTrafficLightCount
            
            allInfoModels.append(aInfoModel)
        }
        bottomInfoView.allRouteInfo = allInfoModels
        
        //默认选择第一条路线
        let selectedRouteID = allInfoModels.first?.routeID
        selectNaviRouteWithID(routeID: selectedRouteID!)
        bottomInfoView.selecteNaviRoute(withRouteID: selectedRouteID!)
    }
    
    func selectNaviRouteWithID(routeID: Int) {
        //在开始导航前进行路径选择
        if driveManager.selectNaviRoute(withRouteID: routeID) {
            selecteOverlayWithRouteID(routeID: routeID)
        }
        else {
            NSLog("路径选择失败!")
        }
    }
    
    func selecteOverlayWithRouteID(routeID: Int) {
        guard let allOverlays = mapView.overlays else {
            return
        }
        
        for (index, aOverlay) in allOverlays.enumerated() {
            
            if let selectableOverlay = aOverlay as? SelectableTrafficOverlay {
                
                /* 获取overlay对应的renderer. */
                let polylineRenderer = mapView.renderer(for: selectableOverlay) as! MAPolylineRenderer
                
                if let overlayRenderer = polylineRenderer as? MAMultiColoredPolylineRenderer {
                    
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
                }
                else if let overlayRenderer = polylineRenderer as? MAMultiTexturePolylineRenderer {
                    
                    if selectableOverlay.routeID == routeID {
                        
                        /* 设置选中状态. */
                        selectableOverlay.selected = true
                        
                        /* 修改renderer选中颜色. */
                        overlayRenderer.strokeTextureImages = selectableOverlay.polylineTextureImages
                        
                        /* 修改overlay覆盖的顺序. */
                        mapView.exchangeOverlay(at: UInt(index), withOverlayAt: UInt(mapView.overlays.count - 1))
                        mapView.showOverlays([aOverlay], animated: true)
                    }
                    else {
                        /* 设置选中状态. */
                        selectableOverlay.selected = false
                        
                        /* 修改renderer选中颜色. */
                        let image = UIImage(named: "custtexture_gray")!
                        overlayRenderer.strokeTextureImages = [image]
                    }
                }
                
                polylineRenderer.glRender()
            }
        }
    }
    
    //MARK: - Handle Navi Route Info
    
    /* 创建路线标签 */
    func createRouteTagString() -> [NSNumber: String]? {
        
        guard let allRoutes = driveManager.naviRoutes else {
            return nil
        }
        
        let allRouteIDs = allRoutes.keys
        let strategy = preferenceView.strategy(withIsMultiple: true)
        
        var minTime = Int.max
        var minLength = Int.max
        var minTrafficLightCount = Int.max
        var minCost = Int.max
        
        for aRoute in allRoutes.values {
            if aRoute.routeTime < minTime {
                minTime = aRoute.routeTime
            }
            
            if aRoute.routeLength < minLength {
                minLength = aRoute.routeLength
            }
            
            if aRoute.routeTrafficLightCount < minTrafficLightCount {
                minTrafficLightCount = aRoute.routeTrafficLightCount
            }
            
            if aRoute.routeTollCost < minCost {
                minCost = aRoute.routeTollCost
            }
        }
        
        var resultDic = [NSNumber: String]()
        for (index, aRouteID) in allRouteIDs.enumerated() {
            
            guard let aRoute = allRoutes[aRouteID] else {
                continue
            }
            
            var resultTag = String.init(format: "方案%d", index + 1)
            
            if aRoute.routeTrafficLightCount <= minTrafficLightCount {
                resultTag = "红绿灯少"
            }
            if aRoute.routeTollCost <= minCost {
                resultTag = "收费较少"
            }
            if Int(aRoute.routeLength / 100) <= Int(minLength / 100) {
                resultTag = "距离最短"
            }
            if aRoute.routeTime < minTime {
                resultTag = "时间最短"
            }
            
            if index == 0 && strategy == .multipleAvoidCongestion {
                resultTag = "躲避拥堵"
            }
            if index == 0 && strategy == .multipleAvoidHighway {
                resultTag = "不走高速"
            }
            if index == 0 && strategy == .multipleAvoidCost {
                resultTag = "避免收费"
            }
            if index == 0 && resultTag.hasPrefix("方案") {
                resultTag = "推荐"
            }
            
            resultDic[aRouteID] = resultTag
        }
        
        return resultDic
    }
    
    func calcDistanceBetween(_ pointA: AMapNaviPoint, and pointB: AMapNaviPoint) -> Double {
        let mapPointA = MAMapPointForCoordinate(CLLocationCoordinate2DMake(CLLocationDegrees(pointA.latitude), CLLocationDegrees(pointA.longitude)))
        let mapPointB = MAMapPointForCoordinate(CLLocationCoordinate2DMake(CLLocationDegrees(pointB.latitude), CLLocationDegrees(pointB.longitude)))
        
        return MAMetersBetweenMapPoints(mapPointA, mapPointB)
    }
    
    func calcPointWith(startPoint: AMapNaviPoint, endPoint: AMapNaviPoint, rate: Double) -> AMapNaviPoint? {
        if rate > 1.0 || rate < 0 {
            return nil
        }
        
        let from = MAMapPointForCoordinate(CLLocationCoordinate2DMake(CLLocationDegrees(startPoint.latitude), CLLocationDegrees(startPoint.longitude)))
        let to = MAMapPointForCoordinate(CLLocationCoordinate2DMake(CLLocationDegrees(endPoint.latitude), CLLocationDegrees(endPoint.longitude)))
        
        let latitudeDelta = (to.y - from.y) * rate
        let longitudeDelta = (to.x - from.x) * rate
        
        let coordinate = MACoordinateForMapPoint(MAMapPointMake(from.x + longitudeDelta, from.y + latitudeDelta))
        
        return AMapNaviPoint.location(withLatitude: CGFloat(coordinate.latitude), longitude: CGFloat(coordinate.longitude))
    }
    
    func defaultColorForStatus(_ status: AMapNaviRouteStatus) -> UIColor {
        switch status {
        case .smooth:
            return UIColor(colorLiteralRed: 65/255.0, green: 223/255.0, blue: 16/255.0, alpha: 1)
        case .slow:
            return UIColor.yellow
        case .jam:
            return UIColor.red
        case .seriousJam:
            return UIColor(colorLiteralRed: 160/255.0, green: 8/255.0, blue: 8/255.0, alpha: 1)
        default:
            return UIColor(colorLiteralRed: 26/255.0, green: 166/255.0, blue: 239/255.0, alpha: 1)
        }
    }
    
    func defaultTextureImageForStatus(_ status: AMapNaviRouteStatus) -> UIImage {
        var imageName = "custtexture_no"
        switch status {
        case .smooth:
            imageName = "custtexture_green"
        case .slow:
            imageName = "custtexture_slow"
        case .jam:
            imageName = "custtexture_bad"
        case .seriousJam:
            imageName = "custtexture_serious"
        default:
            imageName = "custtexture_no"
        }
        return UIImage(named: imageName)!
    }
    
    func addRoutePolylineWithRouteID(_ routeID: Int) {
        
        //用不同颜色表示不同的路况
//        addRoutePolylineUseStrokeColorsWithRouteID(routeID)
        
        //用不同纹理表示不同的路况
        addRoutePolylineUseTextureImagesWithRouteID(routeID)
    }
    
    func addRoutePolylineUseTextureImagesWithRouteID(_ routeID: Int) {
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
        //获取路径的交通状况信息
        guard let trafficStatus = driveManager.getTrafficStatuses(withStartPosition: 0, distance: Int32(aRoute.routeLength)) else {
            return
        }
        
        var resultCoords = Array<AMapNaviPoint>()
        var coordIndexes = Array<NSNumber>()
        var textureImages = Array<UIImage>()
        resultCoords.append(oriCoordinateArray[0])
        
        //依次计算每个路况的长度对应的polyline点的index
        var i = 0
        var sumLength = 0
        var statusesIndex = 0
        var curTrafficLength = (trafficStatus.first?.length)!
        
        for index in 1..<(oriCoordinateArray.count-1) {
            i = index
            
            let segDis = Int(calcDistanceBetween(oriCoordinateArray[i-1], and: oriCoordinateArray[i]))
            
            //两点间插入路况改变的点
            if sumLength + segDis >= curTrafficLength {
                if sumLength + segDis == curTrafficLength {
                    resultCoords.append(oriCoordinateArray[i])
                    coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
                }
                else {
                    let rate = segDis == 0 ? 0 : (curTrafficLength - sumLength) / segDis
                    let extrnPoint = calcPointWith(startPoint: oriCoordinateArray[i-1], endPoint: oriCoordinateArray[i], rate: Double(rate))
                    
                    if extrnPoint != nil {
                        resultCoords.append(extrnPoint!)
                        coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
                        resultCoords.append(oriCoordinateArray[i])
                    }
                    else {
                        resultCoords.append(oriCoordinateArray[i])
                        coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
                    }
                }
                
                //添加对应的strokeColors
                textureImages.append(defaultTextureImageForStatus(trafficStatus[statusesIndex].status))
                
                sumLength = sumLength + segDis - curTrafficLength
                
                statusesIndex += 1
                if statusesIndex >= trafficStatus.count {
                    break
                }
                curTrafficLength = trafficStatus[statusesIndex].length
            }
            else {
                resultCoords.append(oriCoordinateArray[i])
                
                sumLength += segDis
            }
        }
        i += 1
        
        //将最后一个点对齐到路径终点
        if i < oriCoordinateArray.count {
            while i < oriCoordinateArray.count {
                resultCoords.append(oriCoordinateArray[i])
                i += 1
            }
            
            coordIndexes.removeLast()
            coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
        }
        else {
            while Int(coordIndexes.count)-1 >= Int(trafficStatus.count) {
                coordIndexes.removeLast()
                textureImages.removeLast()
            }
            
            coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
            //需要修改textureImages的最后一个与trafficStatus最后一个一致
            textureImages.append(defaultTextureImageForStatus(trafficStatus.last!.status))
        }
        
        //添加Polyline
        var coordinates = Array<CLLocationCoordinate2D>()
        for aCoordinate in resultCoords {
            coordinates.append(CLLocationCoordinate2DMake(CLLocationDegrees(aCoordinate.latitude), CLLocationDegrees(aCoordinate.longitude)))
        }
        
        guard let polyline = SelectableTrafficOverlay(coordinates: &coordinates, count: UInt(coordinates.count), drawStyleIndexes: coordIndexes) else {
            return
        }
        
        polyline.routeID = routeID
        polyline.selected = false
        polyline.polylineWidth = 20
        polyline.polylineTextureImages = textureImages
        
        mapView.add(polyline, level: .aboveLabels)
    }
    
    func addRoutePolylineUseStrokeColorsWithRouteID(_ routeID: Int) {
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
        //获取路径的交通状况信息
        guard let trafficStatus = driveManager.getTrafficStatuses(withStartPosition: 0, distance: Int32(aRoute.routeLength)) else {
            return
        }
        
        var resultCoords = Array<AMapNaviPoint>()
        var coordIndexes = Array<NSNumber>()
        var strokeColors = Array<UIColor>()
        resultCoords.append(oriCoordinateArray[0])
        
        //依次计算每个路况的长度对应的polyline点的index
        var i = 0
        var sumLength = 0
        var statusesIndex = 0
        var curTrafficLength = (trafficStatus.first?.length)!
        
        for index in 1..<(oriCoordinateArray.count-1) {
            i = index
            
            let segDis = Int(calcDistanceBetween(oriCoordinateArray[i-1], and: oriCoordinateArray[i]))
            
            //两点间插入路况改变的点
            if sumLength + segDis >= curTrafficLength {
                if sumLength + segDis == curTrafficLength {
                    resultCoords.append(oriCoordinateArray[i])
                    coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
                }
                else {
                    let rate = segDis == 0 ? 0 : (curTrafficLength - sumLength) / segDis
                    let extrnPoint = calcPointWith(startPoint: oriCoordinateArray[i-1], endPoint: oriCoordinateArray[i], rate: Double(rate))
                    
                    if extrnPoint != nil {
                        resultCoords.append(extrnPoint!)
                        coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
                        resultCoords.append(oriCoordinateArray[i])
                    }
                    else {
                        resultCoords.append(oriCoordinateArray[i])
                        coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
                    }
                }
                
                //添加对应的strokeColors
                strokeColors.append(defaultColorForStatus(trafficStatus[statusesIndex].status))
                
                sumLength = sumLength + segDis - curTrafficLength
                
                statusesIndex += 1
                if statusesIndex >= trafficStatus.count {
                    break
                }
                curTrafficLength = trafficStatus[statusesIndex].length
            }
            else {
                resultCoords.append(oriCoordinateArray[i])
                
                sumLength += segDis
            }
        }
        i += 1
        
        //将最后一个点对齐到路径终点
        if i < oriCoordinateArray.count {
            while i < oriCoordinateArray.count {
                resultCoords.append(oriCoordinateArray[i])
                i += 1
            }
            
            coordIndexes.removeLast()
            coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
        }
        else {
            while Int(coordIndexes.count)-1 >= Int(trafficStatus.count) {
                coordIndexes.removeLast()
                strokeColors.removeLast()
            }
            
            coordIndexes.append(NSNumber(integerLiteral:(Int(resultCoords.count) - 1)))
            //需要修改textureImages的最后一个与trafficStatus最后一个一致
            strokeColors.append(defaultColorForStatus(trafficStatus.last!.status))
        }
        
        //添加Polyline
        var coordinates = Array<CLLocationCoordinate2D>()
        for aCoordinate in resultCoords {
            coordinates.append(CLLocationCoordinate2DMake(CLLocationDegrees(aCoordinate.latitude), CLLocationDegrees(aCoordinate.longitude)))
        }
        
        guard let polyline = SelectableTrafficOverlay(coordinates: &coordinates, count: UInt(coordinates.count), drawStyleIndexes: coordIndexes) else {
            return
        }
        
        polyline.routeID = routeID
        polyline.selected = false
        polyline.polylineWidth = 10
        polyline.polylineStrokeColors = strokeColors
        
        mapView.add(polyline, level: .aboveLabels)
    }
    
    //MARK: - SubViews
    
    func configSubview() {
        
        preferenceView = PreferenceView(frame: CGRect(x: 0, y: 5, width: view.bounds.width, height: 30))
        view.addSubview(preferenceView)
        
        let routeBtn = buttonForTitle("路径规划")
        routeBtn.frame = CGRect(x: (view.bounds.width - 80) / 2.0, y: 40, width: 80, height: 30)
        routeBtn.addTarget(self, action: #selector(self.routePlanAction(sender:)), for: .touchUpInside)
        
        view.addSubview(routeBtn)
        
        bottomInfoView = BottomInfoView(frame: CGRect(x: 0, y: view.bounds.height - 64 - bottomInfoViewHeight, width: view.bounds.width, height: bottomInfoViewHeight))
        bottomInfoView.delegate = self
        
        view.addSubview(bottomInfoView)
        
        let aNilModel = RouteInfoViewModel()
        aNilModel.routeTag = "请在上方进行算路"
        bottomInfoView.allRouteInfo = [aNilModel];
    }
    
    private func buttonForTitle(_ title: String) -> UIButton {
        let reBtn = UIButton(type: .custom)
        
        reBtn.layer.borderColor = UIColor.lightGray.cgColor
        reBtn.layer.borderWidth = 1.0
        reBtn.layer.cornerRadius = 5
        
        reBtn.bounds = CGRect(x: 0, y: 0, width: 80, height: 30)
        reBtn.setTitle(title, for: .normal)
        reBtn.setTitleColor(UIColor.black, for: .normal)
        reBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        return reBtn
    }
    
    //MARK: - BottomInfoView Delegate
    
    func bottomInfoViewSelectedRoute(withRouteID routeID: Int) {
        selectNaviRouteWithID(routeID: routeID)
    }
    
    func bottomInfoViewStartNavi(withRouteID routeID: Int) {
        let driveVC = DriveNaviViewViewController()
        driveVC.delegate = self
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(driveVC.driveView)
        
        _ = navigationController?.pushViewController(driveVC, animated: false)
        driveManager.startEmulatorNavi()
    }
    
    //MARK: - AMapNaviDriveManager Delegate
    
    func driveManager(_ driveManager: AMapNaviDriveManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(onCalculateRouteSuccess driveManager: AMapNaviDriveManager) {
        NSLog("CalculateRouteSuccess")
        
        needRoutePlan = false
        showNaviRoutes()
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, onCalculateRouteFailure error: Error) {
        let error = error as NSError
        NSLog("CalculateRouteFailure:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, didStartNavi naviMode: AMapNaviMode) {
        NSLog("didStartNavi");
    }
    
    func driveManagerNeedRecalculateRoute(forYaw driveManager: AMapNaviDriveManager) {
        NSLog("needRecalculateRouteForYaw");
    }
    
    func driveManagerNeedRecalculateRoute(forTrafficJam driveManager: AMapNaviDriveManager) {
        NSLog("needRecalculateRouteForTrafficJam");
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, onArrivedWayPoint wayPointIndex: Int32) {
        NSLog("ArrivedWayPoint:\(wayPointIndex)");
    }
    
    func driveManagerIsNaviSoundPlaying(_ driveManager: AMapNaviDriveManager) -> Bool {
        return SpeechSynthesizer.Shared.isSpeaking()
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, playNaviSound soundString: String, soundStringType: AMapNaviSoundType) {
        NSLog("playNaviSoundString:{%d:%@}", soundStringType.rawValue, soundString);
        
        SpeechSynthesizer.Shared.speak(soundString)
    }
    
    func driveManagerDidEndEmulatorNavi(_ driveManager: AMapNaviDriveManager) {
        NSLog("didEndEmulatorNavi");
    }
    
    func driveManager(onArrivedDestination driveManager: AMapNaviDriveManager) {
        NSLog("onArrivedDestination");
    }
    
    //MARK: - DriveNaviView Delegate
    
    func driveNaviViewCloseButtonClicked() {
        //开始导航后不再允许选择路径，所以停止导航
        driveManager.stopNavi()
        
        //停止语音
        SpeechSynthesizer.Shared.stopSpeak()
        
        _ = navigationController?.popViewController(animated: false)
    }
    
    //MARK: - MAMapView Delegate
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        
        if annotation is NaviPointAnnotation {
            let annotationIdentifier = "NaviPointAnnotationIdentifier"
            
            var pointAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MAPinAnnotationView
            
            if pointAnnotationView == nil {
                pointAnnotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            
            pointAnnotationView?.animatesDrop = false
            pointAnnotationView?.canShowCallout = true
            pointAnnotationView?.isDraggable = false
            
            let annotation = annotation as! NaviPointAnnotation
            if annotation.naviPointType == .start {
                pointAnnotationView?.pinColor = .green
            }
            else if annotation.naviPointType == .end {
                pointAnnotationView?.pinColor = .red
            }
            
            return pointAnnotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        
        if overlay is SelectableTrafficOverlay {
            let routeOverlay = overlay as! SelectableTrafficOverlay
            
            if routeOverlay.polylineStrokeColors != nil && routeOverlay.polylineStrokeColors.count > 0 {
                let polylineRenderer = MAMultiColoredPolylineRenderer(multiPolyline: routeOverlay)
                
                polylineRenderer?.lineWidth = routeOverlay.polylineWidth
                polylineRenderer?.lineJoinType = kMALineJoinRound
                polylineRenderer?.strokeColors = routeOverlay.polylineStrokeColors
                polylineRenderer?.isGradient = false
                polylineRenderer?.fillColor = UIColor.red
                
                return polylineRenderer
            }
            else if routeOverlay.polylineTextureImages != nil && routeOverlay.polylineTextureImages.count > 0 {
                let polylineRenderer = MAMultiTexturePolylineRenderer(multiPolyline: routeOverlay)
                
                polylineRenderer?.lineWidth = routeOverlay.polylineWidth
                polylineRenderer?.lineJoinType = kMALineJoinRound
                
                polylineRenderer?.strokeTextureImages = routeOverlay.polylineTextureImages
                
                
                return polylineRenderer
            }
        }
        return nil
    }
    
}
