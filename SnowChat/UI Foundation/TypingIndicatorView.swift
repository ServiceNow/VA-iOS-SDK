//
//  TypingIndicatorView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class TypingIndicatorView: UIView {
    
    let dotCount: Int = 3
    let dotDiameter: Int = 10
    let dotSpacing: Int = 15
    
    var color: UIColor = UIColor.userBubbleTextColor {
        didSet {
            (layer as! CAReplicatorLayer).instanceColor = color.cgColor
        }
    }
    
    private let sourceLayer = CAShapeLayer()
    
    var isAnimating: Bool = false
    
    func startAnimating() {
        let indicatorLayer = layer as! CAReplicatorLayer
        let animationDuration = 1.2
        let delay = animationDuration / Double(dotCount)
        indicatorLayer.instanceDelay = delay
        
        // add opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.45
        opacityAnimation.duration = animationDuration * 0.5
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = Float.infinity
        sourceLayer.add(opacityAnimation, forKey: "opacityAnimation")
        isAnimating = true
    }
    
    func stopAnimating() {
        sourceLayer.removeAllAnimations()
        isAnimating = false
    }
    
    override var intrinsicContentSize: CGSize {
        let contentSize = CGSize(width: dotCount * dotDiameter + (dotCount - 1) * (dotSpacing - dotDiameter), height: dotDiameter)
        return contentSize
    }
    
    override class var layerClass: Swift.AnyClass {
        return CAReplicatorLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupIndicatorLayer()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupIndicatorLayer() {
        let indicatorLayer = layer as! CAReplicatorLayer
        
        sourceLayer.fillColor = color.cgColor
        let dotSize = CGSize(width: dotDiameter, height: dotDiameter)
        let circlePath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: dotSize)).cgPath
        sourceLayer.path = circlePath
        sourceLayer.frame = CGRect(origin: CGPoint.zero, size: dotSize)
        
        indicatorLayer.instanceCount = dotCount
        indicatorLayer.instanceTransform = CATransform3DMakeTranslation(CGFloat(dotSpacing), 0, 0)
        indicatorLayer.addSublayer(sourceLayer)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        invalidateIntrinsicContentSize()
    }
}
