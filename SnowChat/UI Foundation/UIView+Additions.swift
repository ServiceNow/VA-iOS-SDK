//
//  UIView+Additions.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

extension UIView {
    class func fromNib() -> UIView {
        let bundle = Bundle(for: self)
        let name = String(describing: self)
        guard let objects = bundle.loadNibNamed(name, owner: self, options: nil) as? [UIView],
            let loadedView = objects.last else {
                fatalError("View doesn't exist")
        }
        
        return loadedView
    }
    
    // Adds circular mask to UIView of the size of view's frame size
    // TODO: It is quick, easy solution to add mask to any view. I need to do more generic solution.
    // There's multiple different ways we could achieve that effect - like applying mask to UIImage itself.
    // For now that should be good enough though.
    func addCircleMaskIfNeeded() {
        guard nil == layer.mask else {
            layer.mask?.frame = bounds
            return
        }
        
        let circlePath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: bounds.size)).cgPath
        let maskLayer = CAShapeLayer()
        maskLayer.path = circlePath
        layer.mask = maskLayer
    }
}
