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
    let path = CGMutablePath()
    path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
    path.addArc(center: CGPoint(x: bounds.minX, y: bounds.maxY - tip), radius: tip, startAngle: 0.5 * (.pi), endAngle: 0, clockwise: true)
    
    path.addArc(center: CGPoint(x: bounds.minX + radius + tip, y: bounds.minY + radius), radius: radius, startAngle: .pi, endAngle: 3.0 * (.pi / 2.0), clockwise: false)
    path.addArc(center: CGPoint(x: bounds.maxX - radius, y: bounds.minY + radius), radius: radius, startAngle: 3.0 * (.pi / 2.0), endAngle: 0, clockwise: false)
    path.addArc(center: CGPoint(x: bounds.maxX - radius, y: bounds.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
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
