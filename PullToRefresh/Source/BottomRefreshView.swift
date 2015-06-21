//
//  BottomRefreshView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/21/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public class BottomRefreshView: UIView {
    public var animating: Bool = true
    private let activityIndicator: UIActivityIndicatorView
    
    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView()

        super.init(frame: frame)

        setupActivityIndicator()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if DEBUG
    deinit {
        print("\(__FILE__):\(__LINE__):\(__FUNCTION__)", appendNewline: true)
    }
    #endif
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard let selfSuperview = superview else {
            return
        }
        center = CGPointMake(CGRectGetMidX(selfSuperview.bounds), CGRectGetMidY(selfSuperview.bounds))
    }
    
    public override func didMoveToWindow() {
        if let _ = window where animating {
            startAnimating()
        }
    }
    
    private func setupActivityIndicator() -> Void {
        activityIndicator.frame = bounds
        activityIndicator.activityIndicatorViewStyle = .Gray
        activityIndicator.hidden = true
        addSubview(activityIndicator)
    }

    public func startAnimating() -> Void {
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
        
        animating = true
    }
    
    public func stopAnimating() -> Void {
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        
        animating = false
    }
}
