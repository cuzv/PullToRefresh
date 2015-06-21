//
//  TopRefreshContainerView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/17/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//
////////////////////////////////////////////////////////
//
//  Copyright (c) 2014, Beamly
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  * Neither the name of Beamly nor the
//  names of its contributors may be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL BEAMLY BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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
















