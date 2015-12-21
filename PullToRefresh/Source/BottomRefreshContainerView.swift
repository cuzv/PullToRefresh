//
//  BottomRefreshContainerView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/17/15.
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
    
    convenience init(height: CGFloat, scrollView: UIScrollView) {
        self.init(height: height, scrollView: scrollView, pullToRefreshType: .InfiniteScroll)
    }
    
    override init(height: CGFloat, scrollView: UIScrollView, pullToRefreshType: PullToRefreshType) {
        super.init(height: height, scrollView: scrollView, pullToRefreshType: pullToRefreshType)
        hidden = !shouldShowWhenDisabled
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented, use init(height:scrollView)")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented, use init(height:scrollView)")
    }
    
    deinit {
        debugPrint("\(__FILE__):\(__LINE__):\(__FUNCTION__)")
    }

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
        if pullToRefreshType == .InfiniteScroll {
            handleInfiniteScrollScrollViewDidScrollToContentOffSet(offSet)
        } else if pullToRefreshType == .LoosenRefresh {
            handleLoosenRefreshScrollViewDidScrollToContentOffSet(offSet)
        }
    }
    
    private func handleInfiniteScrollScrollViewDidScrollToContentOffSet(offSet: CGPoint) -> Void {
        let contentHeight = adjustedHeightFromScrollViewContentSize()
        
        // The lower bound when infinite scroll should kick in
        var actionOffSet = contentHeight - CGRectGetHeight(scrollView.bounds) + scrollView.contentInset.bottom - additionalBottomOffsetForInfinityScrollTrigger
        
        // Prevent conflict with pull to refresh when tableView is too short
        actionOffSet = fmax(actionOffSet, additionalBottomOffsetForInfinityScrollTrigger)
        
        // Disable infinite scroll when scroll view is empty
        // Default UITableView reports height = 1 on empty tables
        let hasActualContent: Bool = scrollView.contentSize.height > 1
        
        if scrollView.dragging && hasActualContent && offSet.y > actionOffSet && state == .None {
            startInfiniteScroll()
        }
    }
    
    private func handleLoosenRefreshScrollViewDidScrollToContentOffSet(offSet: CGPoint) -> Void {
        
    }
    
    // MARK: Refreshing
    
    public func beginRefreshing() -> Void {
        if !enable {
            return
        }
        
        if pullToRefreshType == .InfiniteScroll {
            beginInfiniteScrollRefreshing()
        } else if pullToRefreshType == .LoosenRefresh {
            beginLoosenRefreshRefreshing()
        }
    }
    
    private func beginInfiniteScrollRefreshing() -> Void {
        if state == .None {
            startInfiniteScroll()
        }
    }
    
    private func beginLoosenRefreshRefreshing() -> Void {
        // TODO:
    }
    
    public func endRefreshing() -> Void {
        if pullToRefreshType == .InfiniteScroll {
            endInfiniteScrollRefreshing()
        } else if pullToRefreshType == .LoosenRefresh {
            endLoosenRefreshRefreshing()
        }
    }
    
    private func endInfiniteScrollRefreshing() -> Void {
        endRefreshingWithStoppingContentOffset(false)
    }
    
    private func endLoosenRefreshRefreshing() -> Void {
        // TODO:
    }
    
    // MARK: - Public
    
    public func endRefreshingWithStoppingContentOffset(stopContentOffset: Bool) -> Void {
        if state == .Loading {
            stopInfiniteScrollWithStoppingContentOffset(stopContentOffset)
        }
    }
    
    // MARK: - Private InfiniteScroll
    
    private func startInfiniteScroll() -> Void {
        hidden = false
        
        var contentInset = scrollView.contentInset
        contentInset.bottom += CGRectGetHeight(bounds)
        
        // We have to pad scroll view when content height is smaller than view bounds.
        // This will guarantee that view appears at the very bottom of scroll view.
        let adjustedContentHeight = adjustedHeightFromScrollViewContentSize()
        let extraBottomInset = adjustedContentHeight - scrollView.contentSize.height
        
        // Add empty space padding
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
            self.actionCallback?(scrollView: self.scrollView)
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
        return contentSizeHeight < remainingHeight ? remainingHeight : contentSizeHeight
    }
    
    // MARK: - UIScrollView
    
    private func scrollToInfiniteIndicatorIfNeeded() -> Void {
        if !scrollView.dragging && state == .Loading {
            
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

