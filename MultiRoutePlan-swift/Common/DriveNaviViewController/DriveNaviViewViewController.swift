//
//  DriveNaviViewViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

protocol DriveNaviViewControllerDelegate: NSObjectProtocol {
    func driveNaviViewCloseButtonClicked()
}

class DriveNaviViewViewController: UIViewController, AMapNaviDriveViewDelegate, MoreMenuViewDelegate {
    
    public var delegate: DriveNaviViewControllerDelegate?
    
    public var driveView = AMapNaviDriveView()
    lazy private var moreMenu = MoreMenuView()
    
    //MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configSubviews()
        
        driveView.frame = view.frame
        view .addSubview(driveView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
    }
    
    override func viewWillLayoutSubviews() {
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
            driveView.isLandscape = false
        }
        else if UIInterfaceOrientationIsLandscape(interfaceOrientation) {
            driveView.isLandscape = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func configSubviews() {
        driveView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        driveView.delegate = self
        
        moreMenu.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        moreMenu.delegate = self
    }
    
    //MARK: DriveView Delegate
    func driveViewCloseButtonClicked(_ driveView: AMapNaviDriveView) {
        delegate?.driveNaviViewCloseButtonClicked()
    }
    
    func driveViewMoreButtonClicked(_ driveView: AMapNaviDriveView) {
        moreMenu.trackingMode = self.driveView.trackingMode
        moreMenu.showNightType = self.driveView.showStandardNightType
        
        moreMenu.frame = view.frame
        view.addSubview(moreMenu)
    }
    
    func driveViewTrunIndicatorViewTapped(_ driveView: AMapNaviDriveView) {
        switch driveView.showMode {
        case .carPositionLocked:
            self.driveView.showMode = .normal
        case .normal:
            self.driveView.showMode = .overview
        case .overview:
            self.driveView.showMode = .carPositionLocked
        }
    }
    
    func driveView(_ driveView: AMapNaviDriveView, didChange showMode: AMapNaviDriveViewShowMode) {
        NSLog("didChangeShowMode:%d", showMode.rawValue)
    }
    
    //MARK: MoreMenu Delegate
    
    func moreMenuViewFinishButtonClicked() {
        moreMenu.removeFromSuperview()
    }
    
    func moreMenuViewNightTypeChange(to isShowNightType: Bool) {
        driveView.showStandardNightType = isShowNightType
    }
    
    func moreMenuViewTrackingModeChange(to trackingMode: AMapNaviViewTrackingMode) {
        driveView.trackingMode = trackingMode
    }
}
