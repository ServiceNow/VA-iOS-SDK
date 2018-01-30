//
//  BubbleView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/29/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class BubbleView: UIView, CAAnimationDelegate {
    
    enum ArrowDirection {
        case left
        case right
    }
    
    var arrowDirection: ArrowDirection = .left {
        didSet {
            if arrowDirection == .left {
                contentViewInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            } else {
                contentViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
            }
        }
    }
    
    var insetConstraints = [NSLayoutConstraint]()
    
    var contentViewInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            updateContentViewConstraints()
        }
    }
    
    var contentView = UIView()
    
    var borderColor: UIColor? {
        didSet {
            borderLayer.isHidden = false
            borderLayer.strokeColor = borderColor?.cgColor
        }
    }
    
    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2

        // just to make sure border will be always presented despite adding other sublayers:
        borderLayer.zPosition = 1000
        borderLayer.isHidden = true
        layer.addSublayer(borderLayer)
        return borderLayer
    }()

    convenience init(arrowDirection: ArrowDirection = .left) {
        self.init(frame: CGRect.zero)
        self.arrowDirection = arrowDirection
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShapeLayer()
        setupContentView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        arrowDirection = .left
        contentViewInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        setupContentView()
        setupShapeLayer()
    }
    
    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        updateContentViewConstraints()
    }
    
    private func updateContentViewConstraints() {
        NSLayoutConstraint.deactivate(insetConstraints)
        insetConstraints.removeAll()

        insetConstraints.append(contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentViewInsets.left))
        insetConstraints.append(contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentViewInsets.right))
        insetConstraints.append(contentView.topAnchor.constraint(equalTo: topAnchor, constant: contentViewInsets.top))
        insetConstraints.append(contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentViewInsets.bottom))
        NSLayoutConstraint.activate(insetConstraints)
    }
    
//    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
//        if let shapeLayer = self.layer.mask as? CAShapeLayer, shapeLayer == layer {
//
//            if event == "path" {
//                guard self.layer.action(forKey: "bounds") != nil else {
//                    return nil
//                }
//                let animation = CABasicAnimation(keyPath: "path")
//                animation.delegate = self
//                animation.duration = 5
//                guard let currentBounds = (layer.mask as? CAShapeLayer)?.bounds else { return nil }
//                animation.fromValue = chatBubblePath(forBounds: currentBounds, leftSide: (arrowDirection == .left))
//                return animation
//            }
//        }
//        let action = super.action(for: layer, forKey: event)
//        return action
//    }
    
    func setupShapeLayer() {
        layer.mask = CAShapeLayer()
        layer.mask?.delegate = self
//        layer.backgroundColor = UIColor.red.cgColor
    }
    
    override var bounds: CGRect {
        didSet {
            print("bounds: \(bounds)")
            addMaskPathAnimation()
        }
    }
    
    private func addMaskPathAnimation() {
        guard let currentBounds = (layer.mask as? CAShapeLayer)?.bounds else { return }

        let newPath = chatBubblePath(forBounds: bounds, leftSide: (arrowDirection == .left))
        if layer.action(forKey: "bounds") != nil {
            let fromPath = chatBubblePath(forBounds: currentBounds, leftSide: (arrowDirection == .left))
            (layer.mask as? CAShapeLayer)?.removeAllAnimations()
            borderLayer.removeAllAnimations()
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.delegate = self
            animation.duration = 0.3
            animation.fromValue = fromPath
            animation.toValue = newPath
            (layer.mask as? CAShapeLayer)?.add(animation, forKey: "pathAnim")
            borderLayer.add(animation, forKey: "borderPathAnim")
        }
        (layer.mask as? CAShapeLayer)?.path = newPath
        borderLayer.path = newPath
        
        layer.mask?.frame = bounds
        borderLayer.frame = bounds
    }
}
