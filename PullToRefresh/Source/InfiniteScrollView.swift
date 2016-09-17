//
//  BottomRefreshView.swift
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

import UIKit

public class InfiniteScrollView: UIView {
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
    
    deinit {
        debugPrint("\(#file):\(#line):\(#function)")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard let superview = superview else {
            return
        }
        center = CGPointMake(CGRectGetMidX(superview.bounds), CGRectGetMidY(superview.bounds))
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
