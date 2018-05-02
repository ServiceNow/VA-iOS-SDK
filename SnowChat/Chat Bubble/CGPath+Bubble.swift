//
//  CGPathUtils.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/30/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

func chatBubblePath(forBounds bounds: CGRect, radius: CGFloat = 7, tip: CGFloat = 10, leftSide left: Bool = true) -> CGPath {
    let path = CGMutablePath()
    
    // left bottom - edge of the tip
    path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
    let curveEndPoint = CGPoint(x: bounds.minX + tip, y: bounds.maxY - tip)
    path.addQuadCurve(to: curveEndPoint, control: CGPoint(x: curveEndPoint.x * 0.8, y: bounds.maxY))
    
    // left top corner
    path.addArc(center: CGPoint(x: bounds.minX + radius + tip, y: bounds.minY + radius), radius: radius, startAngle: .pi, endAngle: 3.0 * (.pi / 2.0), clockwise: false)
    
    // right top corner
    path.addArc(center: CGPoint(x: bounds.maxX - radius, y: bounds.minY + radius), radius: radius, startAngle: 3.0 * (.pi / 2.0), endAngle: 0, clockwise: false)
    
    // right bottom corner
    path.addArc(center: CGPoint(x: bounds.maxX - radius, y: bounds.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    
    // left bottom corner
    path.addArc(center: CGPoint(x: bounds.minX + radius + tip, y: bounds.maxY - radius), radius: radius, startAngle: .pi / 2, endAngle: 3 * (.pi / 4), clockwise: false)
    
    path.addQuadCurve(to: CGPoint(x: bounds.minX, y: bounds.maxY), control: CGPoint(x: curveEndPoint.x * 0.8, y: bounds.maxY))
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
