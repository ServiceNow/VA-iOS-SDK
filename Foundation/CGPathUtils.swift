//
//  CGPathUtils.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/30/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

// TODO: move to UIBezierPath
func chatBubblePath(forBounds bounds: CGRect, radius: CGFloat = 7, tip: CGFloat = 10) -> CGPath {
    let rect = bounds
    let path = CGMutablePath()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addArc(center: CGPoint(x: rect.minX, y: rect.maxY - tip), radius: tip, startAngle: 0.5 * (.pi), endAngle: 0, clockwise: true)
    
    path.addArc(center: CGPoint(x: rect.minX + radius + tip, y: rect.minY + radius), radius: radius, startAngle: .pi, endAngle: 3.0 * (.pi / 2.0), clockwise: false)
    path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: 3.0 * (.pi / 2.0), endAngle: 0, clockwise: false)
    path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
}
