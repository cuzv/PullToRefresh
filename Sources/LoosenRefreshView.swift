//
//  TopRefreshView.swift
//  PullToRefresh
//
//  Created by Shaw on 6/20/15.
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

open class LoosenRefreshView: UIView {
    private let backgroundCircluarLayer = CAShapeLayer()
    private let foregroundCircluarLayer = CAShapeLayer()
    private let activityIndicator = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
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
        
        guard let superview = superview else { return }
        center = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
        backgroundCircluarLayer.frame = bounds
        foregroundCircluarLayer.frame = bounds

    }

    open var backgroundCircluarColor: UIColor? {
        get { backgroundCircluarLayer.fillColor.flatMap(UIColor.init(cgColor:)) }
        set { backgroundCircluarLayer.fillColor = newValue?.cgColor }
    }

    open var foregroundCircluarColor: UIColor? {
        get { foregroundCircluarLayer.fillColor.flatMap(UIColor.init(cgColor:)) }
        set { foregroundCircluarLayer.fillColor = newValue?.cgColor }
    }

    open var activityIndicatorColor: UIColor? {
        get { activityIndicator.color }
        set { activityIndicator.color = newValue }
    }
}

extension LoosenRefreshView {
    private func setupCircluarLayer() -> Void {
        let backgroundColor: UIColor
        let foregroundColor: UIColor

        if #available(iOS 13.0, *) {
            backgroundColor = .systemGray6
            foregroundColor = .systemGray
        } else {
            backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
            foregroundColor = .lightGray
        }

        setupCommonCircluarLayer(backgroundCircluarLayer, bounds: bounds, circluarWidth: 2, fillColor: .clear, strokeColor: backgroundColor)
        layer.addSublayer(backgroundCircluarLayer)

        setupCommonCircluarLayer(foregroundCircluarLayer, bounds: bounds, circluarWidth: 2, fillColor: .clear, strokeColor: foregroundColor)
        layer.addSublayer(foregroundCircluarLayer)
        updatePercent(0.0)
    }

    private func setupCommonCircluarLayer(
        _ layer: CAShapeLayer,
        bounds: CGRect,
        circluarWidth: CGFloat,
        fillColor: UIColor,
        strokeColor: UIColor
    ) -> Void {
        let center: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = (bounds.width - circluarWidth) / 2.0
        let startAngle: CGFloat = CGFloat(-90.0).convertAngleToRadian()
        let endAngle: CGFloat = CGFloat(270.0).convertAngleToRadian()
        let path: UIBezierPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        layer.frame = bounds
        layer.fillColor = fillColor.cgColor
        layer.strokeColor = strokeColor.cgColor
        layer.lineCap = .round
        layer.isOpaque = true
        layer.lineWidth = circluarWidth
        layer.path = path.cgPath
        layer.strokeEnd = 1.0
    }

    private func setupSelfLayer() {
        layer.masksToBounds = true
        layer.cornerRadius = min(bounds.midX, bounds.midY)
    }

    private func setupActivityIndicator() -> Void {
        activityIndicator.frame = bounds
        activityIndicator.isHidden = true
        if #available(iOS 13.0, *) {
            activityIndicator.color = .systemGray
        }
        addSubview(activityIndicator)
    }
}

extension LoosenRefreshView: RefreshContainerViewDelegate {
    open func refreshContainerView(_ containerView: RefreshContainerView, didChangeState state: RefreshContainerViewState) -> Void {
        handleStateChange(state)
    }

    open func refreshContainerView(_ containerView: RefreshContainerView, didChangeTriggerStateProgress progress: CGFloat) -> Void {
        handleProgress(progress, forState: containerView.state)
    }

    private func handleStateChange(_ state: RefreshContainerViewState) -> Void {
        if state == .none {
            UIView.animateKeyframes(withDuration: DefaultResetContentInsetAnimationDuration,
                                    delay: 0,
                                    options: .beginFromCurrentState,
                                    animations: { () -> Void in
                                        self.activityIndicator.alpha = 0.0
                                    },
                                    completion: nil)
            updatePercent(0.0)
        } else {
            foregroundCircluarLayer.isHidden = true
            backgroundCircluarLayer.isHidden = true
            activityIndicator.alpha = 1.0
            activityIndicator.startAnimating()
        }
    }

    private func handleProgress(_ progress: CGFloat, forState state: RefreshContainerViewState) -> Void {
        if progress > 0 && state == .none {
            foregroundCircluarLayer.isHidden = false
            backgroundCircluarLayer.isHidden = false
        }

        updatePercent(progress)
    }

    private func updatePercent(_ percent: CGFloat) -> Void {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        foregroundCircluarLayer.strokeEnd = percent
        CATransaction.commit()
    }
}
