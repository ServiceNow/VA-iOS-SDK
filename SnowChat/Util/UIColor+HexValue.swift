//
//  UIColor+HexValue.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension UIColor {
    
    convenience init(hexValue hex: String ) {
        
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count == 3 {
            // special handling for shorthand hex colors: repeat each value before parsing
            let startIndex = cString.startIndex
            var hexString = String(repeating: cString[cString.index(startIndex, offsetBy: 0)], count:2)
            hexString += String(repeating: cString[cString.index(startIndex, offsetBy: 1)], count:2)
            hexString += String(repeating: cString[cString.index(startIndex, offsetBy: 2)], count:2)
            cString = hexString
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
