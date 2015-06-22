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

public class TopRefreshContainerView: RefreshContainerView, RefreshContainerViewSubclassDelegate {

    public var scrollToTopAfterEndRefreshing: Bool = true
    override public var state: RefreshContainerViewState {
        didSet {
            let previousState: RefreshContainerViewState = oldValue
            if state == previousState {
                return
            }
            
            setNeedsLayout()
            layoutIfNeeded()
            
            switch state {
            case .Triggered:
                fallthrough
            case .None:
                resetScrollViewContentInsetWithCompletion(nil)
            case .Loading:
                setScrollViewContentInsetForLoadingAnimated(true)
                if previousState == .Triggered {
                    actionCallback?(scrollView: scrollView)
                }
            }
        }
    }

    private var automaticallyTurnOffAdjustsScrollViewInsetsWhenTranslucentNavigationBar: Bool = true
    private var dragToTriggerOffset: CGFloat = DefaultDragToTriggerOffset

    // MARK: Initializers
    
    override init(height: CGFloat, scrollView: UIScrollView) {
        super.init(height: height, scrollView: scrollView)
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
    
    // MARK: - Public override
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if !automaticallyTurnOffAdjustsScrollViewInsetsWhenTranslucentNavigationBar {
            return
        }
        
        guard let firstReponderViewController = firstResponderViewController() else {
            return
        }
        
        guard let navigationBar = firstReponderViewController.navigationController?.navigationBar else {
            return
        }
        
        if navigationBar.translucent &&
            firstReponderViewController.automaticallyAdjustsScrollViewInsets &&
            scrollView.superview == firstReponderViewController.view {
                firstReponderViewController.automaticallyAdjustsScrollViewInsets = false
                scrollView.contentInset = UIEdgeInsetsMake(navigationBar.frame.origin.y + navigationBar.bounds.size.height,
                    scrollView.contentInset.left,
                    scrollView.contentInset.bottom,
                    scrollView.contentInset.right);
                scrollView.scrollIndicatorInsets = scrollView.contentInset;
        }
    }
    
    // MARK: - RefreshContainerViewSubclassDelegate
    
    internal func resetFrame() -> Void {
        let height = CGRectGetHeight(bounds)
        let width = CGRectGetWidth(scrollView.bounds)
        var newFrame = CGRectMake(-externalContentInset.left, -height, width, height)
        if preserveContentInset {
            newFrame = CGRectMake(0.0, -height - externalContentInset.top, width, height)
        }
        
        frame = newFrame
    }
    
    internal func didSetEnable(enable: Bool) {
        hidden = !enable
    }
    
    // MARK: Observing
    
    internal func observeValueForContentInset(inset: UIEdgeInsets) -> Void {
        let doSomething: () -> Void = {
            self.externalContentInset = inset
            self.resetFrame()
        }
        
        guard let bottomRefreshContainerView = scrollView.bottomRefreshContainerView else {
            doSomething()
            return
        }
        if bottomRefreshContainerView.state == .None {
            doSomething()
        }
    }
    
    internal func scrollViewDidScrollToContentOffSet(offSet: CGPoint) -> Void {
        if state == .Loading {
            var loadingInset = externalContentInset
            var top = loadingInset.top + CGRectGetHeight(bounds)
            
            if isScrollViewIsTableViewAndHaveSections() &&
                scrollView.contentOffset.y > -CGRectGetHeight(bounds) {
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
            if !scrollView.dragging && state == .Triggered {
                changeState(.Loading)
            } else if dragging >= dragToTriggerOffset && scrollView.dragging && state == .None {
                changeState(.Triggered)
            } else if dragging < dragToTriggerOffset && state != .None {
                changeState(.None)
            }
            
            if dragging >= 0 && state != .Loading {
                var progress: CGFloat = dragging * 1.0 / dragToTriggerOffset * 1.0
                if progress > 1.0 {
                    progress = 1.0
                }
                self.delegate?.refreshContainerView?(self, didChangeTriggerStateProgress: progress)
            }
        }
    }
    
    // MARK: Refreshing
    
    public func beginRefreshing() -> Void {
        if !enable {
            return
        }
        if state != .None {
            return
        }
        
        changeState(.Triggered)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.scrollView.setContentOffset(CGPointMake(self.scrollView.contentOffset.x, -CGRectGetHeight(self.frame) - self.externalContentInset.top), animated: true)
        })
        changeState(.Loading)
    }
    
    public func endRefreshing() -> Void {
        if state == .None {
            return
        }
        
        changeState(.None)
        
        if !scrollToTopAfterEndRefreshing {
            return
        }
        
        let originalContentOffset = CGPointMake(-externalContentInset.left, -externalContentInset.top)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.scrollView.setContentOffset(originalContentOffset, animated: false)
        }
    }
    
    // MARK: - Private
    
    private func isScrollViewIsTableViewAndHaveSections() -> Bool {
        if let tableView = scrollView as? UITableView {
            return tableView.numberOfSections > 1 ? true : false
        }
        
        return false
    }
    
    // MARK: UIScrollView

    private func setScrollViewContentInsetForLoadingAnimated(animated: Bool) -> Void {
        var loadingInset = externalContentInset;
        loadingInset.top += CGRectGetHeight(bounds)
        setScrollViewContentInset(loadingInset, forLoadingAnimated: animated)
    }
    
    private func setScrollViewContentInset(inset: UIEdgeInsets, forLoadingAnimated animated: Bool) -> Void {
        setScrollViewContentInset(inset, forLoadingAnimated: animated, completion: nil)
    }
}
