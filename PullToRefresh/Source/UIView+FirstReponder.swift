//
//  UIView+FirstReponder.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/21/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public extension UIView {
    public func firstResponderViewController() -> UIViewController? {
        var responser: UIResponder? = self
        
        while let resp = responser as? UIView {
            responser = resp.nextResponder()
        }
        
        return responser as? UIViewController
    }
}