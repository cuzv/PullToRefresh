//
//  BottomRefreshView.swift
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

import UIKit

open class InfiniteScrollView: UIView {
    private var animating: Bool = true
    private let activityIndicator = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupActivityIndicator()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if DEBUG
    deinit {
        debugPrint("\(#file):\(#line):\(type(of: self)):\(#function)")
    }
    #endif
    
    override open func layoutSubviews() {
        super.layoutSubviews()

        guard let superview = superview else { return }
        center = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
    }
    
    open override func didMoveToWindow() {
        if nil != window , animating {
            startAnimating()
        }
    }
    
    private func setupActivityIndicator() -> Void {
        activityIndicator.frame = bounds
        activityIndicator.isHidden = true
        if #available(iOS 13.0, *) {
            activityIndicator.color = .systemGray
        }
        addSubview(activityIndicator)
    }

    open func startAnimating() -> Void {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        animating = true
    }
    
    open func stopAnimating() -> Void {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        animating = false
    }

    open var activityIndicatorColor: UIColor? {
        get { activityIndicator.color }
        set { activityIndicator.color = newValue }
    }
}
