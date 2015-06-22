//
//  RefreshContainerView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/21/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

// MARK: - Const

public let DefaultResetContentInsetAnimationDuration: NSTimeInterval = 0.3

// MARK: - RefreshContainerViewState

@objc public enum RefreshContainerViewState: Int {
    case None = 0
    case Triggered
    case Loading
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
    
    private weak var subclass: RefreshContainerViewSubclassDelegate!
    
    // MARK: Initializers
    
    public init(height: CGFloat, scrollView: UIScrollView) {
        externalContentInset = scrollView.contentInset
        self.scrollView = scrollView
        
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
        let options: UIViewAnimationOptions = [.AllowUserInteraction, .BeginFromCurrentState]
        UIView.animateWithDuration(DefaultResetContentInsetAnimationDuration,
            delay: 0,
            options: options,
            animations: { () -> Void in
                self.setScrollViewContentInset(self.externalContentInset)
            },
            completion: completion)
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