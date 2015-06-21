//
//  BottomRefreshContainerView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/17/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public class BottomRefreshContainerView: RefreshContainerView, RefreshContainerViewSubclassDelegate {

    public var additionalBottomOffsetForInfinityScrollTrigger: CGFloat = 0.0
    private var infiniteScrollBottomContentInset: CGFloat = 0.0
    private var shouldShowWhenDisabled: Bool = false {
        didSet {
            if shouldShowWhenDisabled {
                hidden = false
            } else {
                hidden = state == .None
            }
        }
    }
    
    // MARK: Initializers
    
    override init(height: CGFloat, scrollView: UIScrollView) {
        super.init(height: height, scrollView: scrollView)
        hidden = !shouldShowWhenDisabled
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented, use init(height:scrollView)")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented, use init(height:scrollView)")
    }
    
    #if DEBUG
    deinit {
        print("\(__FILE__):\(__LINE__):\(__FUNCTION__)", appendNewline: true)
    }
    #endif


    // MARK: - RefreshContainerViewSubclassDelegate
    
    internal func resetFrame() -> Void {
        let height = CGRectGetHeight(bounds)
        let width = CGRectGetWidth(scrollView.bounds)
        let contentHeight = adjustedHeightFromScrollViewContentSize()
        var newFrame = CGRectMake(-externalContentInset.left, contentHeight, width, height)
        if preserveContentInset {
            newFrame = CGRectMake(0.0, contentHeight + externalContentInset.bottom, width, height)
        }
        frame = newFrame
    }
    
    internal func didSetEnable(enable: Bool) {
        if !shouldShowWhenDisabled {
            hidden = !enable
        }
    }
    
    // MARK: Observing

    internal func observeValueForContentInset(inset: UIEdgeInsets) -> Void {
        let doSomething: () -> Void = {
            self.externalContentInset = inset
            self.resetFrame()
        }
        
        guard let topRefreshContainerView = scrollView.topRefreshContainerView else {
            doSomething()
            return
        }
        if topRefreshContainerView.state == .None {
            doSomething()
        }
    }
    
    internal func scrollViewDidScrollToContentOffSet(offSet: CGPoint) -> Void {
        let contentHeight = adjustedHeightFromScrollViewContentSize()

        // The lower bound when infinite scroll should kick in
        var actionOffSet = contentHeight - CGRectGetHeight(scrollView.bounds) + scrollView.contentInset.bottom - additionalBottomOffsetForInfinityScrollTrigger

        // Prevent conflict with pull to refresh when tableView is too short
        actionOffSet = fmax(actionOffSet, additionalBottomOffsetForInfinityScrollTrigger)
        
        // Disable infinite scroll when scroll view is empty
        // Default UITableView reports height = 1 on empty tables
        let hasActualContent = scrollView.contentSize.height > 1
        if scrollView.dragging && hasActualContent && offSet.y > actionOffSet {
            startInfiniteScroll()
        }
    }
    
    // MARK: Refreshing
    
    public func beginRefreshing() -> Void {
        if !enable {
            return
        }
        
        if state == .None {
            startInfiniteScroll()
        }
    }
    
    public func endRefreshing() -> Void {
        endRefreshingWithStoppingContentOffset(false)
    }
    
    // MARK: - Public
    
    public func endRefreshingWithStoppingContentOffset(stopContentOffset: Bool) -> Void {
        if state == .Loading {
            stopInfiniteScrollWithStoppingContentOffset(stopContentOffset)
        }
    }
    
    // MARK: - Private
    
    private func startInfiniteScroll() -> Void {
        hidden = false
        
        var contentInset = scrollView.contentInset
        contentInset.bottom += CGRectGetHeight(bounds)
        
        // We have to pad scroll view when content height is smaller than view bounds.
        // This will guarantee that view appears at the very bottom of scroll view.
        let adjustedContentHeight = adjustedHeightFromScrollViewContentSize()
        let extraBottomInset = adjustedContentHeight - scrollView.contentSize.height
        
        contentInset.bottom += extraBottomInset
        
        // Save extra inset
        infiniteScrollBottomContentInset = extraBottomInset
        
        changeState(.Loading)
        
        setScrollViewContentInset(contentInset, forLoadingAnimated: true) { [weak self] (finished: Bool) -> Void in
            if let strongSelf = self where finished {
                strongSelf.scrollToInfiniteIndicatorIfNeeded()
            }
        }
        
        // This will delay handler execution until scroll deceleration
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(100 * NSEC_PER_MSEC)), dispatch_get_main_queue()) { () -> Void in
            actionCallback?(scrollView: scrollView)
        }
    }
    
    private func stopInfiniteScrollWithStoppingContentOffset(stopContentOffset: Bool) -> Void {
        var contentInset = scrollView.contentInset
        contentInset.bottom -= CGRectGetHeight(bounds)
        
        // remove extra inset added to pad infinite scroll
        contentInset.bottom -= infiniteScrollBottomContentInset
        
        let offSet = scrollView.contentOffset
        setScrollViewContentInset(contentInset, forLoadingAnimated: !stopContentOffset) { [weak self] (finished: Bool) -> Void in
            if let strongSelf = self {
                if stopContentOffset {
                    strongSelf.scrollView.contentOffset = offSet
                }
                if finished {
                    if !strongSelf.shouldShowWhenDisabled {
                        strongSelf.hidden = true
                    }
                    strongSelf.resetScrollViewContentInsetWithCompletion({ (finished) -> Void in
                        strongSelf.changeState(.None)
                    })
                }
            }
        }
    }
    
    private func adjustedHeightFromScrollViewContentSize() -> CGFloat {
        let remainingHeight = CGRectGetHeight(bounds) - scrollView.contentInset.top - scrollView.contentInset.bottom
        let contentSizeHeight = scrollView.contentSize.height
        if contentSizeHeight < remainingHeight {
            return remainingHeight
        }
        
        return contentSizeHeight
    }
    
    // MARK: - UIScrollView
    
    private func scrollToInfiniteIndicatorIfNeeded() -> Void {
        if scrollView.dragging && state == .Loading {
            // adjust content height for case when contentSize smaller than view bounds
            let contentHeight = adjustedHeightFromScrollViewContentSize()
            let height = CGRectGetHeight(bounds)
            
            let bottomBarHeight = scrollView.contentInset.bottom - height
            let minY = contentHeight - CGRectGetHeight(scrollView.bounds) + bottomBarHeight
            let maxY = minY + height
            
            let contentOffsetY = scrollView.contentOffset.y
            
            if minY < contentOffsetY && contentOffsetY < maxY {
                scrollView.setContentOffset(CGPointMake(0, maxY), animated: true)
            }
        }
    }
}











