//
//  UIScrollView+PullToRefresh.swift
//  PullToRefresh
//
//  Created by Shaw on 6/19/15.
//  Copyright © 2015 ReadRain. All rights reserved.
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

extension UIScrollView {
    private struct AssociatedKeys {
        static var topRefreshContainerKey = "com.mochxiao.pulltorefresh.topRefreshContainerKey"
        static var bottomRefreshContainerKey = "com.mochxiao.pulltorefresh.BottomRefreshContainerKey"
    }
    
    public var topRefreshContainerView: TopRefreshContainerView? {
        set {
            willChangeValue(forKey: AssociatedKeys.topRefreshContainerKey)
            objc_setAssociatedObject(self, &AssociatedKeys.topRefreshContainerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            didChangeValue(forKey: AssociatedKeys.topRefreshContainerKey)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.topRefreshContainerKey) as? TopRefreshContainerView
        }
    }
    
    public var bottomRefreshContainerView: BottomRefreshContainerView? {
        set {
            willChangeValue(forKey: AssociatedKeys.bottomRefreshContainerKey)
            objc_setAssociatedObject(self, &AssociatedKeys.bottomRefreshContainerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            didChangeValue(forKey: AssociatedKeys.bottomRefreshContainerKey)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.bottomRefreshContainerKey) as? BottomRefreshContainerView
        }
    }
}

// MARK: - TopRefreshContainerView

extension UIScrollView {
    public func addTopRefreshContainerView(height: CGFloat, handler: RefreshActionHandler?) -> Void {
        let topRefreshContainerView: TopRefreshContainerView = TopRefreshContainerView(height: height, scrollView: self)
        addSubview(topRefreshContainerView)
        self.topRefreshContainerView = topRefreshContainerView
        self.topRefreshContainerView?.actionHandler = handler
    }
    
    public func removeTopPullToRefresh() -> Void {
        endTopPullToRefresh()
        topRefreshContainerView?.removeFromSuperview()
        topRefreshContainerView = nil
    }
    
    public func beginTopPullToRefresh() -> Void {
        topRefreshContainerView?.beginRefreshing()
    }
    
    public func endTopPullToRefresh() -> Void {
        topRefreshContainerView?.endRefreshing()
    }
    
    public func setTopPullToRefresh(enable: Bool) -> Void {
        topRefreshContainerView?.enable = enable
    }
}

// MARK: - BottomRefreshContainerView

extension UIScrollView {
    public func addBottomRefreshContainerView(height: CGFloat, handler: RefreshActionHandler?) -> Void {
        let bottomRefreshContainerView: BottomRefreshContainerView = BottomRefreshContainerView(height: height, scrollView: self)
        addSubview(bottomRefreshContainerView)
        self.bottomRefreshContainerView = bottomRefreshContainerView
        self.bottomRefreshContainerView?.actionHandler = handler
    }
    
    public func removeBottomPullToRefresh() -> Void {
        endBottomPullToRefresh()
        bottomRefreshContainerView?.removeFromSuperview()
        bottomRefreshContainerView = nil
    }
    
    public func beginBottomPullToRefresh() -> Void {
        bottomRefreshContainerView?.beginRefreshing()
    }
    
    public func endBottomPullToRefresh() -> Void {
        bottomRefreshContainerView?.endRefreshing()
    }
    
    public func endBottomPullToRefresh(withStoppingContentOffset stopContentOffset: Bool) -> Void {
        bottomRefreshContainerView?.endRefreshingWithStoppingContentOffset(stopContentOffset)
    }
    
    public func setBottomPullToRefresh(enable: Bool) -> Void {
        bottomRefreshContainerView?.enable = enable
    }
}
