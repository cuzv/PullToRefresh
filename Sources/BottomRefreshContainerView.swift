//
//  BottomRefreshContainerView.swift
//  PullToRefresh
//
//  Created by Shaw on 6/17/15.
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

open class BottomRefreshContainerView: RefreshContainerView, RefreshContainerViewSubclassDelegate {
    open var additionalBottomOffsetForInfinityScrollTrigger: CGFloat = 0.0
    private var infiniteScrollBottomContentInset: CGFloat = 0.0
    private var shouldShowWhenDisabled: Bool = false {
        didSet {
            if shouldShowWhenDisabled {
                isHidden = false
            } else {
                isHidden = state == .none
            }
        }
    }
    
    // MARK: Initializers
    
    convenience init(height: CGFloat, scrollView: UIScrollView) {
        self.init(height: height, scrollView: scrollView, pullToRefreshType: .infiniteScroll)
    }
    
    override init(height: CGFloat, scrollView: UIScrollView, pullToRefreshType: PullToRefreshType) {
        super.init(height: height, scrollView: scrollView, pullToRefreshType: pullToRefreshType)
        isHidden = !shouldShowWhenDisabled
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented, use init(height:scrollView)")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented, use init(height:scrollView)")
    }

    // MARK: - RefreshContainerViewSubclassDelegate
    
    internal func resetFrame() -> Void {
        let height = bounds.height
        let width = scrollView.bounds.width
        let contentHeight = adjustedHeightFromScrollViewContentSize()
        var newFrame = CGRect(x: -externalContentInset.left, y: contentHeight, width: width, height: height)
        if preserveContentInset {
            newFrame = CGRect(x: 0.0, y: contentHeight + externalContentInset.bottom, width: width, height: height)
        }
        frame = newFrame
    }
    
    internal func didSetEnable(_ enable: Bool) {
        if !shouldShowWhenDisabled {
            isHidden = !enable
        }
    }
    
    // MARK: Observing

    internal func observeValue(forContentInset inset: UIEdgeInsets) -> Void {
        let doSomething: () -> Void = {
            self.externalContentInset = inset
            self.resetFrame()
        }
        
        guard let topRefreshContainerView = scrollView.topRefreshContainerView else {
            doSomething()
            return
        }
        if topRefreshContainerView.state == .none {
            doSomething()
        }
    }
    
    internal func scrollViewDidScroll(toContentOffSet offSet: CGPoint) -> Void {
        if pullToRefreshType == .infiniteScroll {
            handleInfiniteScrollScrollViewDidScrollToContentOffSet(offSet)
        } else if pullToRefreshType == .loosenRefresh {
            handleLoosenRefreshScrollViewDidScrollToContentOffSet(offSet)
        }
    }
    
    private func handleInfiniteScrollScrollViewDidScrollToContentOffSet(_ offSet: CGPoint) -> Void {
        let contentHeight = adjustedHeightFromScrollViewContentSize()
        
        // The lower bound when infinite scroll should kick in
        var actionOffSet = contentHeight - scrollView.bounds.height + scrollView.contentInset.bottom - additionalBottomOffsetForInfinityScrollTrigger
        
        // Prevent conflict with pull to refresh when tableView is too short
        actionOffSet = fmax(actionOffSet, additionalBottomOffsetForInfinityScrollTrigger)
        
        // Disable infinite scroll when scroll view is empty
        // Default UITableView reports height = 1 on empty tables
        let hasActualContent: Bool = scrollView.contentSize.height > 1
        
        if scrollView.isDragging && hasActualContent && offSet.y > actionOffSet && state == .none {
            startInfiniteScroll()
        }
    }
    
    private func handleLoosenRefreshScrollViewDidScrollToContentOffSet(_ offSet: CGPoint) -> Void {
        
    }
    
    // MARK: Refreshing
    
    open func beginRefreshing() -> Void {
        if !enable {
            return
        }
        
        if pullToRefreshType == .infiniteScroll {
            beginInfiniteScrollRefreshing()
        } else if pullToRefreshType == .loosenRefresh {
            beginLoosenRefreshRefreshing()
        }
    }
    
    private func beginInfiniteScrollRefreshing() -> Void {
        if state == .none {
            startInfiniteScroll()
        }
    }
    
    private func beginLoosenRefreshRefreshing() -> Void {
        // TODO:
    }
    
    open func endRefreshing() -> Void {
        if pullToRefreshType == .infiniteScroll {
            endInfiniteScrollRefreshing()
        } else if pullToRefreshType == .loosenRefresh {
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
    
    open func endRefreshingWithStoppingContentOffset(_ stopContentOffset: Bool) -> Void {
        if state == .loading {
            stopInfiniteScrollWithStoppingContentOffset(stopContentOffset)
        }
    }
    
    // MARK: - Private InfiniteScroll
    
    private func startInfiniteScroll() -> Void {
        isHidden = false
        
        var contentInset = scrollView.contentInset
        contentInset.bottom += bounds.height
        
        // We have to pad scroll view when content height is smaller than view bounds.
        // This will guarantee that view appears at the very bottom of scroll view.
        let adjustedContentHeight = adjustedHeightFromScrollViewContentSize()
        let extraBottomInset = adjustedContentHeight - scrollView.contentSize.height
        
        // Add empty space padding
        contentInset.bottom += extraBottomInset
        
        // Save extra inset
        infiniteScrollBottomContentInset = extraBottomInset
        
        changeState(.loading)
        
        setScrollViewContentInset(contentInset, forLoadingAnimated: true) { [weak self] (finished: Bool) -> Void in
            if let strongSelf = self , finished {
                strongSelf.scrollToInfiniteIndicatorIfNeeded()
            }
        }
        
        // This will delay handler execution until scroll deceleration
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(100 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)) { () -> Void in
            self.actionHandler?(self.scrollView)
        }
    }
    
    private func stopInfiniteScrollWithStoppingContentOffset(_ stopContentOffset: Bool) -> Void {
        var contentInset = scrollView.contentInset
        contentInset.bottom -= bounds.height
        
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
                        strongSelf.isHidden = true
                    }
                    strongSelf.resetScrollViewContentInsetWithCompletion({ (finished) -> Void in
                        strongSelf.changeState(.none)
                    })
                }
            }
        }
    }
    
    private func adjustedHeightFromScrollViewContentSize() -> CGFloat {
        let remainingHeight = bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let contentSizeHeight = scrollView.contentSize.height
        return contentSizeHeight < remainingHeight ? remainingHeight : contentSizeHeight
    }
    
    // MARK: - UIScrollView
    
    private func scrollToInfiniteIndicatorIfNeeded() -> Void {
        if !scrollView.isDragging && state == .loading {
            
            // adjust content height for case when contentSize smaller than view bounds
            let contentHeight = adjustedHeightFromScrollViewContentSize()
            let height = bounds.height
            
            let bottomBarHeight = scrollView.contentInset.bottom - height
            let minY = contentHeight - scrollView.bounds.height + bottomBarHeight
            let maxY = minY + height
            
            let contentOffsetY = scrollView.contentOffset.y
            
            if minY < contentOffsetY && contentOffsetY < maxY {
                scrollView.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
            }
        }
    }
    
    #if DEBUG
    deinit {
        debugPrint("\(#file):\(#line):\(type(of: self)):\(#function)")
    }
    #endif
}

