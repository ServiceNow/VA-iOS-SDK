//
//  BubbleView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/29/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class BubbleView: UIView {
    
    var borderColor: UIColor = UIColor.red
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addShapeLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addShapeLayer() {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = chatBubblePath(forBounds: bounds)
        layer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        (layer.mask as? CAShapeLayer)?.path = chatBubblePath(forBounds: bounds)
    }
}
