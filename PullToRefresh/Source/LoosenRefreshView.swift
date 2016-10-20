//
//  TopRefreshView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/20/15.
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

open class LoosenRefreshView: UIView, RefreshContainerViewDelegate {
    
    fileprivate let backCircluarLayer: CAShapeLayer
    fileprivate let frontCircluarLayer: CAShapeLayer
    fileprivate let activityIndicator: UIActivityIndicatorView
    
    override init(frame: CGRect) {
        backCircluarLayer = CAShapeLayer()
        frontCircluarLayer = CAShapeLayer()
        activityIndicator = UIActivityIndicatorView()
        
        super.init(frame: frame)
        
        setupCircluarLayer()
        setupSelfLayer()
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
        
        guard let superview = superview else {
            return
        }
        center = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
        backCircluarLayer.frame = bounds
        frontCircluarLayer.frame = bounds
    }
    
    // MARK: Private custom
    
    fileprivate func setupCircluarLayer() -> Void {
        setupCommonCircluarLayer(backCircluarLayer, bounds: bounds, circluarWidth: 2, fillColor: UIColor.clear, strokeColor: UIColor.lightGray.withAlphaComponent(0.5))
        layer.addSublayer(backCircluarLayer)
        
        setupCommonCircluarLayer(frontCircluarLayer, bounds: bounds, circluarWidth: 2, fillColor: UIColor.clear, strokeColor: UIColor.lightGray)
        layer.addSublayer(frontCircluarLayer)
        updatePercent(0.0)
    }
    
    fileprivate func setupCommonCircluarLayer(_ layer: CAShapeLayer, bounds: CGRect, circluarWidth: CGFloat, fillColor: UIColor, strokeColor: UIColor) -> Void {
        let center: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = (bounds.width - circluarWidth) / 2.0
        let startAngle: CGFloat = CGFloat(-90.0).convertAngleToRadian()
        let endAngle: CGFloat = CGFloat(270.0).convertAngleToRadian()
        let path: UIBezierPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        layer.frame = bounds
        layer.fillColor = fillColor.cgColor
        layer.strokeColor = strokeColor.cgColor
        layer.lineCap = kCALineJoinRound
        layer.isOpaque = true
        layer.lineWidth = circluarWidth
        layer.path = path.cgPath
        layer.strokeEnd = 1.0
    }
    
    fileprivate func setupSelfLayer() -> Void {
        layer.masksToBounds = true
        layer.cornerRadius = min(bounds.midX, bounds.midY)
    }
    
    fileprivate func updatePercent(_ percent: CGFloat) -> Void {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        frontCircluarLayer.strokeEnd = percent
        CATransaction.commit()
    }
    
    fileprivate func setupActivityIndicator() -> Void {
        activityIndicator.frame = bounds
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.isHidden = true
        addSubview(activityIndicator)
    }
    
    // MARK: TopRefreshContainerViewDelegate
    
    open func refreshContainerView(_ containerView: RefreshContainerView, didChangeState state: RefreshContainerViewState) -> Void {
        handleStateChange(state)
    }
    
    open func refreshContainerView(_ containerView: RefreshContainerView, didChangeTriggerStateProgress progress: CGFloat) -> Void {
        handleProgress(progress, forState: containerView.state)
    }

    fileprivate func handleStateChange(_ state: RefreshContainerViewState) -> Void {
        if state == .none {
            UIView.animateKeyframes(withDuration: DefaultResetContentInsetAnimationDuration,
                delay: 0,
                options: UIViewKeyframeAnimationOptions.beginFromCurrentState,
                animations: { () -> Void in
                    self.activityIndicator.alpha = 0.0
                },
                completion: nil)
            updatePercent(0.0)
        } else {
            frontCircluarLayer.isHidden = true
            backCircluarLayer.isHidden = true
            activityIndicator.alpha = 1.0
            activityIndicator.startAnimating()
        }
    }
    
    fileprivate func handleProgress(_ progress: CGFloat, forState state: RefreshContainerViewState) -> Void {
        if progress > 0 && state == .none {
            frontCircluarLayer.isHidden = false
            backCircluarLayer.isHidden = false
        }
        
        updatePercent(progress)
    }
}
