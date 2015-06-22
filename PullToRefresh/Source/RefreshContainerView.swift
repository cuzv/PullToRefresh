//
//  RefreshContainerView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/21/15.
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

// MARK: - RefreshContainerViewState

@objc public enum RefreshContainerViewState: Int {
    case None = 0
    case Triggered
    case Loading
}

@objc public enum PullToRefreshType: Int {
    case LoosenRefresh
    case InfiniteScroll
}

// MARK: - RefreshContainerViewDelegate

@objc public protocol RefreshContainerViewDelegate {
    optional func refreshContainerView(containerView: RefreshContainerView, didChangeState state: RefreshContainerViewState) -> Void
    optional func refreshContainerView(containerView: RefreshContainerView, didChangeTriggerStateProgress progress: CGFloat) -> Void
}

// MARK: - RefreshContainerViewSubclassDelegate

@objc internal protocol RefreshContainerViewSubclassDelegate {
    func resetFrame() -> Void
    func didSetEnable(enable: Bool) -> Void    
    func observeValueForContentInset(inset: UIEdgeInsets) -> Void
    func scrollViewDidScrollToContentOffSet(offSet: CGPoint) -> Void
    func beginRefreshing() -> Void
    func endRefreshing() -> Void
}

// MARK: - RefreshActionCallback

public typealias RefreshActionCallback = ((scrollView: UIScrollView) -> Void)

// MARK: - RefreshContainerView

public class RefreshContainerView: UIView {
    public var state: RefreshContainerViewState = .None
    public weak var delegate: RefreshContainerViewDelegate?
    public var actionCallback: RefreshActionCallback?
    public var preserveContentInset: Bool = false {
        didSet {
            if bounds.size.height > 0.0 {
                subclass.resetFrame()
            }
        }
    }
    
    public var enable: Bool = true {
        didSet {
            if enable == oldValue {
                return
            }
            if enable {
                subclass.resetFrame()
            } else {
                subclass.endRefreshing()
            }
            subclass.didSetEnable(enable)
        }
    }
    internal unowned let scrollView: UIScrollView
    internal var externalContentInset: UIEdgeInsets
    internal var updatingScrollViewContentInset: Bool = false
    internal let pullToRefreshType: PullToRefreshType
    
    private weak var subclass: RefreshContainerViewSubclassDelegate!
    
    // MARK: Initializers
    
    public init(height: CGFloat, scrollView: UIScrollView, pullToRefreshType: PullToRefreshType) {
        externalContentInset = scrollView.contentInset
        self.scrollView = scrollView
        self.pullToRefreshType = pullToRefreshType
        
        let frame =  CGRectMake(0, 0, 0, height)
        super.init(frame: frame)
        
        subclass = self as? RefreshContainerViewSubclassDelegate
        assert(nil != subclass, "Self's Subclasses must conformsToProtocol `RefreshContainerViewSubclassDelegate`")
        
        autoresizingMask = .FlexibleWidth
        subclass.resetFrame()
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
    
    // MARK: - Internal
    
    internal func changeState(state: RefreshContainerViewState) -> Void {
        if self.state == state {
            return
        }
        self.state = state
        
        delegate?.refreshContainerView?(self, didChangeState: state)
    }
    
    // MARK: UIScrollView
    
    internal func resetScrollViewContentInsetWithCompletion(completion: ((finished: Bool) -> Void)?) {
        resetScrollViewContentInsetWithCompletion(completion, animated: true)
    }

    internal func resetScrollViewContentInsetWithCompletion(completion: ((finished: Bool) -> Void)?, animated: Bool) {
        if animated {
            let options: UIViewAnimationOptions = [.AllowUserInteraction, .BeginFromCurrentState]
            UIView.animateWithDuration(DefaultResetContentInsetAnimationDuration,
                delay: 0,
                options: options,
                animations: { () -> Void in
                    self.setScrollViewContentInset(self.externalContentInset)
                },
                completion: completion)
        } else {
            setScrollViewContentInset(self.externalContentInset)
            completion?(finished: true)
        }
    }
    
    internal func setScrollViewContentInset(inset: UIEdgeInsets) -> Void {
        let alreadyUpdating = updatingScrollViewContentInset
        if !alreadyUpdating {
            updatingScrollViewContentInset = true
        }
        scrollView.contentInset = inset
        if !alreadyUpdating {
            updatingScrollViewContentInset = false
        }
    }
    
    internal func setScrollViewContentInset(inset: UIEdgeInsets, forLoadingAnimated animated: Bool, completion: ((finished: Bool) -> Void)?) -> Void {
        let updateClosure: () -> Void = {
            () -> Void in
            self.setScrollViewContentInset(inset)
        }
        
        if animated {
            let options: UIViewAnimationOptions = [.AllowUserInteraction, .BeginFromCurrentState]
            UIView.animateWithDuration(DefaultResetContentInsetAnimationDuration, delay: 0, options: options, animations: updateClosure, completion: completion)
        } else {
            UIView.performWithoutAnimation(updateClosure)
            if nil != completion {
                completion?(finished: true)
            }
        }
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
    
    private func removeObserversFromView(view: UIView) -> Void {
        assert(nil != view as? UIScrollView, "Self's superview must be kind of `UIScrollView`")
        
        view.removeObserver(self, forKeyPath: "contentOffset")
        view.removeObserver(self, forKeyPath: "contentSize")
        view.removeObserver(self, forKeyPath: "frame")
        view.removeObserver(self, forKeyPath: "contentInset")
    }
    
    private func addScrollViewObservers(view: UIView) -> Void {
        assert(nil != view as? UIScrollView, "Self's superview must be kind of `UIScrollView`")
        
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
            subclass.scrollViewDidScrollToContentOffSet(offSet)
        } else if keyPath == "contentSize" {
            layoutSubviews()
            subclass.resetFrame()
        } else if keyPath == "frame" {
            layoutSubviews()
        } else if keyPath == "contentInset" {
            if !updatingScrollViewContentInset {
                guard let contentInset = change?[NSKeyValueChangeNewKey]?.UIEdgeInsetsValue() else {
                    return
                }
                subclass.observeValueForContentInset(contentInset)
            }
        }
    }
}