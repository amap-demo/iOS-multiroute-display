//
//  NaviPointAnnotation.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

enum NaviPointAnnotationType: Int {
    case start
    case way
    case end
}

class NaviPointAnnotation: MAPointAnnotation {
    var naviPointType: NaviPointAnnotationType?
}
