//
//  CGPathUtils.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/30/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

// TODO: move to UIBezierPath
func chatBubblePath(forBounds bounds: CGRect, radius: CGFloat = 7, tip: CGFloat = 10, leftSide left: Bool = true) -> CGPath {
    var localRadius = radius
    if bounds.height < 15 {
        localRadius = 0
    }
    
    let path = CGMutablePath()
    path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
    path.addArc(center: CGPoint(x: bounds.minX, y: bounds.maxY - tip), radius: tip, startAngle: 0.5 * (.pi), endAngle: 0, clockwise: true)
    
    path.addArc(center: CGPoint(x: bounds.minX + localRadius + tip, y: bounds.minY + localRadius), radius: localRadius, startAngle: .pi, endAngle: 3.0 * (.pi / 2.0), clockwise: false)
    path.addArc(center: CGPoint(x: bounds.maxX - localRadius, y: bounds.minY + localRadius), radius: localRadius, startAngle: 3.0 * (.pi / 2.0), endAngle: 0, clockwise: false)
    path.addArc(center: CGPoint(x: bounds.maxX - localRadius, y: bounds.maxY - localRadius), radius: localRadius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
    path.closeSubpath()
    
    // flip cgpath if needed
    if !left {
        var transform = CGAffineTransform(translationX: bounds.width, y: 0).scaledBy(x: -1, y: 1)
        if let copyPath = path.mutableCopy(using: &transform) {
            return copyPath
        }
    }
    
    return path
}
