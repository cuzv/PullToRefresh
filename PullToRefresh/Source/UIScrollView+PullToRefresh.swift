//
//  UIScrollView+PullToRefresh.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/19/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public extension UIScrollView {
    private struct AssociatedKeys {
        static var topRefreshContainerKey = "topRefreshContainerKey"
        static var bottomRefreshContainerKey = "BottomRefreshContainerKey"
    }
    
    public var topRefreshContainerView: TopRefreshContainerView? {
        set {
            willChangeValueForKey(AssociatedKeys.topRefreshContainerKey)
            objc_setAssociatedObject(self, &AssociatedKeys.topRefreshContainerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            didChangeValueForKey(AssociatedKeys.topRefreshContainerKey)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.topRefreshContainerKey) as? TopRefreshContainerView
        }
    }
    
    public var bottomRefreshContainerView: BottomRefreshContainerView? {
        set {
            willChangeValueForKey(AssociatedKeys.bottomRefreshContainerKey)
            objc_setAssociatedObject(self, &AssociatedKeys.bottomRefreshContainerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            didChangeValueForKey(AssociatedKeys.bottomRefreshContainerKey)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.bottomRefreshContainerKey) as? BottomRefreshContainerView
        }
    }
}

// MARK: - TopRefreshContainerView

public extension UIScrollView {
    public func addTopRefreshContainerViewWithHeight(height: CGFloat, actionCallback: RefreshActionCallback?) -> Void {
        removeTopPullToRefresh()
        
        let topRefreshContainerView: TopRefreshContainerView = TopRefreshContainerView(height: height, scrollView: self)
        addSubview(topRefreshContainerView)
        self.topRefreshContainerView = topRefreshContainerView
        self.topRefreshContainerView?.actionCallback = actionCallback
    }
    
    public func removeTopPullToRefresh() -> Void {
        topRefreshContainerView?.removeFromSuperview()
        topRefreshContainerView = nil
    }
    
    public func beginToPullToRefresh() -> Void {
        topRefreshContainerView?.beginRefreshing()
    }
    
    public func endTopPullToRefresh() -> Void {
        topRefreshContainerView?.endRefreshing()
    }
    
    public func setTopPullToRefreshEnable(enable: Bool) -> Void {
        topRefreshContainerView?.enable = enable
    }
}

// MARK: - BottomRefreshContainerView

public extension UIScrollView {
    public func addBottomRefreshContainerViewWithHeight(height: CGFloat, actionCallback: RefreshActionCallback?) -> Void {
        removeBottomPullToRefresh()
        
        let bottomRefreshContainerView: BottomRefreshContainerView = BottomRefreshContainerView(height: height, scrollView: self)
        addSubview(bottomRefreshContainerView)
        self.bottomRefreshContainerView = bottomRefreshContainerView
        self.bottomRefreshContainerView?.actionCallback = actionCallback
    }
    
    public func removeBottomPullToRefresh() -> Void {
        bottomRefreshContainerView?.removeFromSuperview()
        bottomRefreshContainerView = nil
    }
    
    public func beginBottomPullToRefresh() -> Void {
        bottomRefreshContainerView?.beginRefreshing()
    }
    
    public func endBottomPullToRefresh() -> Void {
        bottomRefreshContainerView?.endRefreshing()
    }
    
    public func endBottomPullToRefreshWithStoppingContentOffset(stopContentOffset: Bool) -> Void {
        bottomRefreshContainerView?.endRefreshingWithStoppingContentOffset(stopContentOffset)
    }
    
    public func setBottomPullToRefreshEnable(enable: Bool) -> Void {
        bottomRefreshContainerView?.enable = enable
    }
}