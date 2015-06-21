//
//  TopRefreshView.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/20/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public class TopRefreshView: UIView, RefreshContainerViewDelegate {
    
    private let backCircluarLayer: CAShapeLayer
    private let frontCircluarLayer: CAShapeLayer
    private let activityIndicator: UIActivityIndicatorView
    
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
        print("\(__FILE__):\(__LINE__):\(__FUNCTION__)", appendNewline: true)
    }
    #endif
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard let selfSuperview = superview else {
            return
        }
        center = CGPointMake(CGRectGetMidX(selfSuperview.bounds), CGRectGetMidY(selfSuperview.bounds))
        backCircluarLayer.frame = bounds
        frontCircluarLayer.frame = bounds
    }
    
    // MARK: Private custom
    
    private func setupCircluarLayer() -> Void {
        setupCommonCircluarLayer(backCircluarLayer, bounds: bounds, circluarWidth: 2, fillColor: UIColor.clearColor(), strokeColor: UIColor.lightGrayColor().colorWithAlphaComponent(0.5))
        layer.addSublayer(backCircluarLayer)
        
        setupCommonCircluarLayer(frontCircluarLayer, bounds: bounds, circluarWidth: 2, fillColor: UIColor.clearColor(), strokeColor: UIColor.lightGrayColor())
        layer.addSublayer(frontCircluarLayer)
        updatePercent(0.0)
    }
    
    private func setupCommonCircluarLayer(layer: CAShapeLayer, bounds: CGRect, circluarWidth: CGFloat, fillColor: UIColor, strokeColor: UIColor) -> Void {
        let center: CGPoint = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        let radius: CGFloat = (CGRectGetWidth(bounds) - circluarWidth) / 2.0
        let startAngle: CGFloat = CGFloat(-90.0).convertAngleToRadian()
        let endAngle: CGFloat = CGFloat(270.0).convertAngleToRadian()
        let path: UIBezierPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        layer.frame = bounds
        layer.fillColor = fillColor.CGColor
        layer.strokeColor = strokeColor.CGColor
        layer.lineCap = kCALineJoinRound
        layer.opaque = true
        layer.lineWidth = circluarWidth
        layer.path = path.CGPath
        layer.strokeEnd = 1.0
    }
    
    private func setupSelfLayer() -> Void {
        layer.masksToBounds = true
        layer.cornerRadius = min(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
    }
    
    private func updatePercent(percent: CGFloat) -> Void {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        frontCircluarLayer.strokeEnd = percent
        CATransaction.commit()
    }
    
    private func setupActivityIndicator() -> Void {
        activityIndicator.frame = bounds
        activityIndicator.activityIndicatorViewStyle = .Gray
        activityIndicator.hidden = true
        addSubview(activityIndicator)
    }
    
    // MARK: TopRefreshContainerViewDelegate
    
    public func refreshContainerView(containerView: RefreshContainerView, didChangeState state: RefreshContainerViewState) -> Void {
        handleStateChange(state)
    }
    
    public func refreshContainerView(containerView: RefreshContainerView, didChangeTriggerStateProgress progress: CGFloat) -> Void {
        handleProgress(progress, forState: containerView.state)
    }

    private func handleStateChange(state: RefreshContainerViewState) -> Void {
        print("\(__FUNCTION__)", appendNewline: true)
        if state == .None {
            UIView.animateKeyframesWithDuration(DefaultResetContentInsetAnimationDuration,
                delay: 0,
                options: UIViewKeyframeAnimationOptions.BeginFromCurrentState,
                animations: { () -> Void in
                    self.activityIndicator.alpha = 0.0
                },
                completion: nil)
            updatePercent(0.0)
        } else {
            frontCircluarLayer.hidden = true
            backCircluarLayer.hidden = true
            activityIndicator.alpha = 1.0
            activityIndicator.startAnimating()
        }
    }
    
    private func handleProgress(progress: CGFloat, forState state: RefreshContainerViewState) -> Void {
        if progress > 0 && state == .None {
            frontCircluarLayer.hidden = false
            backCircluarLayer.hidden = false
        }
        
        updatePercent(progress)
    }
}