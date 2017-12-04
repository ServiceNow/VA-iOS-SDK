//
//  UIImageUtils.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

func circleImage(withDiamater diameter: CGFloat, color: UIColor, borderWidth border: CGFloat = 0, borderColor: UIColor? = nil) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0.0)
    guard let context = UIGraphicsGetCurrentContext() else {
        return nil
    }
    
    let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
    context.setFillColor(color.cgColor)
    context.addEllipse(in: rect)
    context.fillEllipse(in: rect)
    
    if let borderColor = borderColor, border > 0 {
        context.setLineWidth(border)
        context.setStrokeColor(borderColor.cgColor)
        context.strokeEllipse(in: rect)
    }
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
