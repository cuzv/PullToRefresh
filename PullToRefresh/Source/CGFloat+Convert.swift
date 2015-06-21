//
//  CGFloat+Convert.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/21/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public extension CGFloat {
    public func convertAngleToRadian() -> CGFloat {
        return CGFloat(self.native * M_PI / 180.0)
    }
    
    public func convertRadianToAngle() -> CGFloat {
        return CGFloat(self.native * 180.0 / M_PI)
    }
}