//
//  RefreshContainerView.swift
//  PullToRefresh
//
//  Created by Shaw on 6/21/15.
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

public let DefaultResetContentInsetAnimationDuration: TimeInterval = 0.3

// MARK: - RefreshContainerViewState

@objc public enum RefreshContainerViewState: Int {
    case none = 0
    case triggered
    case loading
}

@objc public enum PullToRefreshType: Int {
    case loosenRefresh
    case infiniteScroll
}

// MARK: - RefreshContainerViewDelegate

@objc public protocol RefreshContainerViewDelegate {
    @objc optional func refreshContainerView(_ containerView: RefreshContainerView, didChangeState state: RefreshContainerViewState) -> Void
    @objc optional func refreshContainerView(_ containerView: RefreshContainerView, didChangeTriggerStateProgress progress: CGFloat) -> Void
}

// MARK: - RefreshContainerViewSubclassDelegate

@objc internal protocol RefreshContainerViewSubclassDelegate {
    func resetFrame() -> Void
    func didSetEnable(_ enable: Bool) -> Void    
    func observeValue(forContentInset inset: UIEdgeInsets) -> Void
    func scrollViewDidScroll(toContentOffSet offSet: CGPoint) -> Void
    func beginRefreshing() -> Void
    func endRefreshing() -> Void
}

// MARK: - RefreshActionHandler

public typealias RefreshActionHandler = ((_ scrollView: UIScrollView) -> Void)

// MARK: - RefreshContainerView

open class RefreshContainerView: UIView {
    open var state: RefreshContainerViewState = .none
    open weak var delegate: RefreshContainerViewDelegate?
    open var actionHandler: RefreshActionHandler?
    open var preserveContentInset: Bool = false {
        didSet {
            if bounds.size.height > 0.0 {
                subclass.resetFrame()
            }
        }
    }
    
    open var enable: Bool = true {
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
        
        let frame =  CGRect(x: 0, y: 0, width: 0, height: height)
        super.init(frame: frame)
        
        subclass = self as? RefreshContainerViewSubclassDelegate
        assert(nil != subclass, "Self's Subclasses must conformsToProtocol `RefreshContainerViewSubclassDelegate`")
        
        autoresizingMask = .flexibleWidth
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
        debugPrint("\(#file):\(#line):\(type(of: self)):\(#function)")
    }
    #endif
    
    // MARK: - Internal
    
    internal func changeState(_ state: RefreshContainerViewState) -> Void {
        if self.state == state {
            return
        }
        self.state = state
        
        delegate?.refreshContainerView?(self, didChangeState: state)
    }
    
    // MARK: UIScrollView
    
    internal func resetScrollViewContentInsetWithCompletion(_ completion: ((_ finished: Bool) -> Void)?) {
        resetScrollViewContentInsetWithCompletion(completion, animated: true)
    }

    internal func resetScrollViewContentInsetWithCompletion(_ completion: ((_ finished: Bool) -> Void)?, animated: Bool) {
        if animated {
            let options: UIView.AnimationOptions = [.allowUserInteraction, .beginFromCurrentState]
            UIView.animate(withDuration: DefaultResetContentInsetAnimationDuration,
                delay: 0,
                options: options,
                animations: {
                    self.setScrollViewContentInset(self.externalContentInset)
                },
                completion: completion)
        } else {
            setScrollViewContentInset(self.externalContentInset)
            completion?(true)
        }
    }
    
    internal func setScrollViewContentInset(_ inset: UIEdgeInsets) -> Void {
        let alreadyUpdating = updatingScrollViewContentInset
        if !alreadyUpdating {
            updatingScrollViewContentInset = true
        }
        scrollView.contentInset = inset
        if !alreadyUpdating {
            updatingScrollViewContentInset = false
        }
    }
    
    internal func setScrollViewContentInset(_ inset: UIEdgeInsets, forLoadingAnimated animated: Bool, completion: ((_ finished: Bool) -> Void)?) -> Void {
        let updateClosure: () -> Void = {
            () -> Void in
            self.setScrollViewContentInset(inset)
        }
        
        if animated {
            let options: AnimationOptions = [.allowUserInteraction, .beginFromCurrentState]
            UIView.animate(withDuration: DefaultResetContentInsetAnimationDuration, delay: 0, options: options, animations: updateClosure, completion: completion)
        } else {
            UIView.performWithoutAnimation(updateClosure)
            if nil != completion {
                completion?(true)
            }
        }
    }
    
    // MARK: Observing
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let superview = superview {
            removeObserversFromView(superview)
        }
        
        if let newSuperview = newSuperview {
            addScrollViewObservers(newSuperview)
        }
    }
    
    private func removeObserversFromView(_ view: UIView) -> Void {
        assert(nil != view as? UIScrollView, "Self's superview must be kind of `UIScrollView`")
        
        view.removeObserver(self, forKeyPath: "contentOffset")
        view.removeObserver(self, forKeyPath: "contentSize")
        view.removeObserver(self, forKeyPath: "frame")
        view.removeObserver(self, forKeyPath: "contentInset")
    }
    
    private func addScrollViewObservers(_ view: UIView) -> Void {
        assert(nil != view as? UIScrollView, "Self's superview must be kind of `UIScrollView`")
        
        view.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil)
        view.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.new, context: nil)
        view.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.new, context: nil)
        view.addObserver(self, forKeyPath: "contentInset", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !enable {
            return
        }
        
//        let value = change?[NSKeyValueChangeNewKey]
//        debugPrint("\(keyPath): \(value)")
        
        if keyPath == "contentOffset" {
            guard let offSet = ((change?[NSKeyValueChangeKey.newKey]) as AnyObject).cgPointValue else {
                return
            }
            subclass.scrollViewDidScroll(toContentOffSet: offSet)
        } else if keyPath == "contentSize" {
            layoutSubviews()
            subclass.resetFrame()
        } else if keyPath == "frame" {
            layoutSubviews()
        } else if keyPath == "contentInset" {
            if !updatingScrollViewContentInset {
                guard let contentInset = ((change?[NSKeyValueChangeKey.newKey]) as AnyObject).uiEdgeInsetsValue else {
                    return
                }
                subclass.observeValue(forContentInset: contentInset)
            }
        }
    }
}
