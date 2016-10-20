//
//  TopRefreshContainerView.swift
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

// MARK: - Const

public let DefaultDragToTriggerOffset: CGFloat = 80.0

// MARK: - TopRefreshContainerView

open class TopRefreshContainerView: RefreshContainerView, RefreshContainerViewSubclassDelegate {

    open var scrollToTopAfterEndRefreshing: Bool = true
    override open var state: RefreshContainerViewState {
        didSet {
            let previousState: RefreshContainerViewState = oldValue
            if state == previousState {
                return
            }
            
            setNeedsLayout()
            layoutIfNeeded()
            
            switch state {
            case .triggered:
                fallthrough
            case .none:
                resetScrollViewContentInsetWithCompletion(nil, animated: scrollToTopAfterEndRefreshing)
            case .loading:
                setScrollViewContentInsetForLoadingAnimated(true)
                if previousState == .triggered {
                    previousContentHeight = scrollView.contentSize.height
                    previousContentOffY = scrollView.contentOffset.y
                    actionHandler?(scrollView)
                }
            }
        }
    }

    fileprivate var automaticallyTurnOffAdjustsScrollViewInsetsWhenTranslucentNavigationBar: Bool = true
    fileprivate var dragToTriggerOffset: CGFloat = DefaultDragToTriggerOffset
    fileprivate var previousContentOffY: CGFloat = 0.0
    fileprivate var previousContentHeight: CGFloat = 0.0

    // MARK: Initializers
    
    override init(height: CGFloat, scrollView: UIScrollView, pullToRefreshType: PullToRefreshType) {
        super.init(height: height, scrollView: scrollView, pullToRefreshType: pullToRefreshType)
    }
    
    convenience init(height: CGFloat, scrollView: UIScrollView) {
        self.init(height: height, scrollView: scrollView, pullToRefreshType: .loosenRefresh)
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented, use init(height:scrollView)")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented, use init(height:scrollView)")
    }
    
    #if DEBUG
    deinit {
        debugPrint("\(#file):\(#line):\(type(of: self)):\(#function)")
    }
    #endif

    // MARK: - Public override
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if !automaticallyTurnOffAdjustsScrollViewInsetsWhenTranslucentNavigationBar {
            return
        }
        
        guard let firstReponderViewController = firstResponderViewController else {
            return
        }
        
        guard let navigationBar = firstReponderViewController.navigationController?.navigationBar else {
            return
        }
        
        if navigationBar.isTranslucent &&
            firstReponderViewController.automaticallyAdjustsScrollViewInsets &&
            scrollView.superview == firstReponderViewController.view
        {
            firstReponderViewController.automaticallyAdjustsScrollViewInsets = false
            var bottomAddition: CGFloat = 0
            if let tabBar = firstReponderViewController.tabBarController?.tabBar , !tabBar.isHidden {
                bottomAddition = tabBar.bounds.height
            }
            scrollView.contentInset = UIEdgeInsetsMake(
                scrollView.contentInset.top + navigationBar.frame.maxY,
                scrollView.contentInset.left,
                scrollView.contentInset.bottom + bottomAddition,
                scrollView.contentInset.right);
            scrollView.scrollIndicatorInsets = scrollView.contentInset;
        }
    }
    
    // MARK: - RefreshContainerViewSubclassDelegate
    
    internal func resetFrame() -> Void {
        let height = bounds.height
        let width = scrollView.bounds.width
        var newFrame = CGRect(x: -externalContentInset.left, y: -height, width: width, height: height)
        if preserveContentInset {
            newFrame = CGRect(x: 0.0, y: -height - externalContentInset.top, width: width, height: height)
        }
        
        frame = newFrame
    }
    
    internal func didSetEnable(_ enable: Bool) {
        isHidden = !enable
    }
    
    // MARK: Observing
    
    internal func observeValue(forContentInset inset: UIEdgeInsets) -> Void {
        let doSomething: () -> Void = {
            self.externalContentInset = inset
            self.resetFrame()
        }
        
        guard let bottomRefreshContainerView = scrollView.bottomRefreshContainerView else {
            doSomething()
            return
        }
        if bottomRefreshContainerView.state == .none {
            doSomething()
        }
    }
    
    internal func scrollViewDidScroll(toContentOffSet offSet: CGPoint) -> Void {
        if state == .loading {
            var loadingInset = externalContentInset
            var top = loadingInset.top + bounds.height
            
            if isScrollViewIsTableViewAndHaveSections() &&
                scrollView.contentOffset.y > -bounds.height {
                    if scrollView.contentOffset.y >= 0 {
                        top = loadingInset.top
                    } else {
                        top = fabs(scrollView.contentOffset.y)
                    }
            }
            loadingInset.top = top
            setScrollViewContentInset(loadingInset, forLoadingAnimated: false)
        } else {
            let dragging = -offSet.y - externalContentInset.top
            if !scrollView.isDragging && state == .triggered {
                changeState(.loading)
            } else if dragging >= dragToTriggerOffset && scrollView.isDragging && state == .none {
                changeState(.triggered)
            } else if dragging < dragToTriggerOffset && state != .none {
                changeState(.none)
            }
            
            if dragging >= 0 && state != .loading {
                var progress: CGFloat = dragging * 1.0 / dragToTriggerOffset * 1.0
                if progress > 1.0 {
                    progress = 1.0
                }
                self.delegate?.refreshContainerView?(self, didChangeTriggerStateProgress: progress)
            }
        }
    }
    
    // MARK: Refreshing
    
    open func beginRefreshing() -> Void {
        if !enable {
            return
        }
        if state != .none {
            return
        }
        
        changeState(.triggered)
        DispatchQueue.main.async(execute: { () -> Void in
            self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x, y: -self.frame.height - self.externalContentInset.top), animated: true)
        })
        changeState(.loading)
    }
    
    open func endRefreshing() -> Void {
        if state == .none {
            return
        }
        
        changeState(.none)
        
        if !scrollToTopAfterEndRefreshing {
            let nowContentHeight = scrollView.contentSize.height
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: nowContentHeight - previousContentHeight + previousContentOffY)
            return
        }
        
        let originalContentOffset = CGPoint(x: -externalContentInset.left, y: -externalContentInset.top)
        DispatchQueue.main.async { () -> Void in
            self.scrollView.setContentOffset(originalContentOffset, animated: false)
        }
    }
    
    // MARK: - Private
    
    fileprivate func isScrollViewIsTableViewAndHaveSections() -> Bool {
        if let tableView = scrollView as? UITableView {
            return tableView.numberOfSections > 1 ? true : false
        }
        
        return false
    }
    
    // MARK: UIScrollView

    fileprivate func setScrollViewContentInsetForLoadingAnimated(_ animated: Bool) -> Void {
        var loadingInset = externalContentInset;
        loadingInset.top += bounds.height
        setScrollViewContentInset(loadingInset, forLoadingAnimated: animated)
    }
    
    fileprivate func setScrollViewContentInset(_ inset: UIEdgeInsets, forLoadingAnimated animated: Bool) -> Void {
        setScrollViewContentInset(inset, forLoadingAnimated: animated, completion: nil)
    }
}
