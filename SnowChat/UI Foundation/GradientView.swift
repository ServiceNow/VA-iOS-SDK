//
//  GradientView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMaskLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMaskLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor, UIColor.white.cgColor]
        gradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        layer.mask = gradientLayer
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        layer.mask?.frame = layer.bounds
    }
}
