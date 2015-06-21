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

public let DefaultResetContentInsetAnimationDuration: NSTimeInterval = 0.3
public let DefaultDragToTriggerOffset: CGFloat = 80

// MARK: - TopRefreshContainerViewState

@objc public enum TopRefreshContainerViewState: Int {
    case None = 0
    case Triggered
    case Loading
}

@objc public protocol TopRefreshContainerViewDelegate {
    optional func topRefreshContainerView(containerView: TopRefreshContainerView, didChangeState state: TopRefreshContainerViewState) -> Void
    optional func topRefreshContainerView(containerView: TopRefreshContainerView, didChangeTriggerStateProgress progress: CGFloat) -> Void
}

public typealias RefreshActionCallback = ((scrollView: UIScrollView) -> Void)

// MARK: - TopRefreshContainerView

public class TopRefreshContainerView: UIView {
    
    public var actionCallback: RefreshActionCallback?
    public weak var delegate: TopRefreshContainerViewDelegate?
    public var scrollToTopAfterEndRefreshing: Bool = true
    public var state: TopRefreshContainerViewState = .None {
        didSet {
            let previousState: TopRefreshContainerViewState = oldValue
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
    public var enable: Bool = true {
        didSet {
            if enable == oldValue {
                return
            }
            if enable {
                resetFrame()
            } else {
                endRefreshing()
            }
            hidden = !enable;
        }
    }
    public var preserveContentInset: Bool = false {
        didSet {
            if bounds.size.height > 0.0 {
                resetFrame()
            }
        }
    }

    private var automaticallyTurnOffAdjustsScrollViewInsetsWhenTranslucentNavigationBar: Bool = true
    private var dragToTriggerOffset: CGFloat = DefaultDragToTriggerOffset
    private var scrollView: UIScrollView
    private var externalContentInset: UIEdgeInsets
    private var updatingScrollViewContentInset: Bool = false
    
    // MARK: Initializers
    
    public init(height: CGFloat, scrollView: UIScrollView) {
        self.scrollView = scrollView
        externalContentInset = scrollView.contentInset

        let frame =  CGRectMake(0, 0, 0, height)
        super.init(frame: frame)
        
        autoresizingMask = .FlexibleWidth
        resetFrame()
    }

    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented, use init(height:scrollView)")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented, use init(height:scrollView)")
    }
    
    // MARK: Public
    
    func beginRefreshing() -> Void {
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
    
    func endRefreshing() -> Void {
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
    
    func changeState(state: TopRefreshContainerViewState) -> Void {
        if self.state == state {
            return
        }
        self.state = state
        
        delegate?.topRefreshContainerView?(self, didChangeState: state)
    }
    
    // MARK: Observing
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        if let superview = superview {
            removeObserversFromView(superview)
        }
        
        if let newSuperview = newSuperview {
            addScrollViewObservers(newSuperview)
        }
    }
    
    public override func didMoveToSuperview() {
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
    
    private func removeObserversFromView(view: UIView) -> Void {
        assert(view as? UIScrollView != nil)
        
        view.removeObserver(self, forKeyPath: "contentOffset")
        view.removeObserver(self, forKeyPath: "contentSize")
        view.removeObserver(self, forKeyPath: "frame")
        view.removeObserver(self, forKeyPath: "contentInset")
    }
    
    private func addScrollViewObservers(view: UIView) -> Void {
        assert(view as? UIScrollView != nil)
        
        view.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
        view.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
        view.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: nil)
        view.addObserver(self, forKeyPath: "contentInset", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !enable {
            return
        }

//        let value = change?[NSKeyValueChangeNewKey]
//        print("\(keyPath): \(value)", appendNewline: true)
        
        if keyPath == "contentOffset" {
            guard let offSet = change?[NSKeyValueChangeNewKey]?.CGPointValue else {
                return
            }
            scrollViewDidScrollToContentOffSet(offSet)
        } else if keyPath == "contentSize" {
            layoutSubviews()
            resetFrame()
        } else if keyPath == "frame" {
            layoutSubviews()
        } else if keyPath == "contentInset" {
            // Prevent to change external content inset when infinity scroll is loading
            if !updatingScrollViewContentInset {
                guard let contentInset = change?[NSKeyValueChangeNewKey]?.UIEdgeInsetsValue() else {
                    return
                }
                
                let doSomething: () -> Void = {
                    self.externalContentInset = contentInset
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
        }
    }
    
    private func scrollViewDidScrollToContentOffSet(offSet: CGPoint) -> Void {
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
                self.delegate?.topRefreshContainerView?(self, didChangeTriggerStateProgress: progress)
            }
        }
    }
    
    private func isScrollViewIsTableViewAndHaveSections() -> Bool {
        if let tableView = scrollView as? UITableView {
            return tableView.numberOfSections > 1 ? true : false
        }
        
        return false
    }
    
    // MARK: UIScrollView
    
    private func resetScrollViewContentInsetWithCompletion(completion: ((finished: Bool) -> Void)?) {
        let options: UIViewAnimationOptions = [.AllowUserInteraction, .BeginFromCurrentState]
        UIView.animateWithDuration(DefaultResetContentInsetAnimationDuration,
            delay: 0,
            options: options,
            animations: { () -> Void in
                self.setScrollViewContentInset(self.externalContentInset)
            },
            completion: completion)
    }

    private func setScrollViewContentInset(inset: UIEdgeInsets) -> Void {
        let alreadyUpdating = updatingScrollViewContentInset
        if !alreadyUpdating {
            updatingScrollViewContentInset = true
        }
        scrollView.contentInset = inset
        if !alreadyUpdating {
            updatingScrollViewContentInset = false
        }
    }
    
    private func setScrollViewContentInsetForLoadingAnimated(animated: Bool) -> Void {
        var loadingInset = externalContentInset;
        loadingInset.top += CGRectGetHeight(bounds)
        setScrollViewContentInset(loadingInset, forLoadingAnimated: animated)
    }
    
    private func setScrollViewContentInset(inset: UIEdgeInsets, forLoadingAnimated animated: Bool) -> Void {
        let updateClosure: () -> Void = {
            () -> Void in
            self.setScrollViewContentInset(inset)
        }

        if animated {
            let options: UIViewAnimationOptions = [.AllowUserInteraction, .BeginFromCurrentState]
            UIView.animateWithDuration(DefaultResetContentInsetAnimationDuration, delay: 0, options: options, animations: updateClosure, completion: nil)
        } else {
            updateClosure()
        }
    }
    
    // MARK: Utils

    func resetFrame() -> Void {
        let height = CGRectGetHeight(bounds)
        var frame = CGRectMake(-externalContentInset.left, -height, CGRectGetWidth(scrollView.bounds), height)
        if preserveContentInset {
            frame = CGRectMake(0.0, -height - externalContentInset.top, CGRectGetWidth(scrollView.bounds), height)
        }
        
        self.frame = frame
    }
}
















