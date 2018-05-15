//
//  GradientView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    var locations: [NSNumber] = [] {
        didSet {
            (layer.mask as? CAGradientLayer)?.locations = locations
        }
    }
    
    var colors: [UIColor] = [] {
        didSet {
            (layer.mask as? CAGradientLayer)?.colors = colors.map({ $0.cgColor })
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMaskLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMaskLayer()
    }
    
    private func setupMaskLayer() {
        let gradientLayer = CAGradientLayer()
        
        // Some default values
        gradientLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.locations = [0, 0.2, 0.8, 1]
        layer.mask = gradientLayer
        layer.backgroundColor = UIColor.white.cgColor
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        layer.mask?.frame = layer.bounds
    }
}
