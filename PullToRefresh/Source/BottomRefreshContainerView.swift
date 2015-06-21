//
//  BottomRefreshContainerView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/17/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

// MARK: - BottomRefreshContainerViewState

@objc public enum BottomRefreshContainerViewState: Int {
    case None = 0
    case Loading
}

public class BottomRefreshContainerView: UIView {

    public var state: BottomRefreshContainerViewState = .None
    
}
