//
//  RoundedView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

protocol Roundable where Self: UIView {
    var roundedPath: CGPath? { get }
    func addRoundedMaskLayer()
    func addRoundedCorners(_ corners: UIRectCorner, cornerRadii: CGSize)
}

extension Roundable {
    var roundedPath: CGPath? {
        guard let shapeLayer = layer.mask as? CAShapeLayer,
            let path = shapeLayer.path else {
                return nil
        }
        
        return path
    }
    
    func addRoundedMaskLayer() {
        let maskLayer = CAShapeLayer()
        layer.mask = maskLayer
    }
    
    func addRoundedCorners(_ corners: UIRectCorner, cornerRadii: CGSize) {
        guard let maskLayer = layer.mask as? CAShapeLayer else {
            fatalError("Please call addMaskLayer: first in order to add rounded corners")
        }
        
        let borderPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: cornerRadii)
        maskLayer.frame = bounds
        maskLayer.path = borderPath.cgPath
    }
}

@IBDesignable
class RoundedView: UIView, Roundable {
    
    @IBInspectable var cornerRadius: CGFloat = 2
    var roundedCorners: UIRectCorner = UIRectCorner.allCorners

    var borderColor: UIColor = UIColor.clear {
        didSet {
            borderLayer.strokeColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderLineWidth: CGFloat = 0 {
        didSet {
            borderLayer.lineWidth = borderLineWidth
        }
    }
    
    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.fillColor = nil
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderLineWidth
        layer.addSublayer(borderLayer)
        return borderLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        addRoundedMaskLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        addRoundedCorners([.bottomLeft, .bottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        borderLayer.path = roundedPath
    }
}
