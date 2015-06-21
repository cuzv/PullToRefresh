//
//  UIScrollView+PullToRefresh.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/19/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public extension UIScrollView {
    private struct AssociatedKeys {
        static var topRefreshContainerKey = "topRefreshContainerKey"
        static var bottomRefreshContainerKey = "BottomRefreshContainerKey"
    }
    
    public var topRefreshContainerView: TopRefreshContainerView? {
        set {
            willChangeValueForKey("topRefreshContainerView")
            objc_setAssociatedObject(self, &AssociatedKeys.topRefreshContainerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            didChangeValueForKey("topRefreshContainerView")
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.topRefreshContainerKey) as? TopRefreshContainerView
        }
    }
    
    public var bottomRefreshContainerView: BottomRefreshContainerView? {
        set {
            willChangeValueForKey("bottomRefreshContainerView")
            objc_setAssociatedObject(self, &AssociatedKeys.bottomRefreshContainerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            didChangeValueForKey("bottomRefreshContainerView")
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.bottomRefreshContainerKey) as? BottomRefreshContainerView
        }
    }
    
    // MARK: - TopRefreshContainerView
    
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
        self.topRefreshContainerView?.beginRefreshing()
    }
    
    public func endTopPullToRefresh() -> Void {
        self.topRefreshContainerView?.endRefreshing()
    }
    
    public func setTopPullToRefreshEnable(enable: Bool) -> Void {
        self.topRefreshContainerView?.enable = enable
    }
    
    // MARK: - BottomRefreshContainerView
    
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