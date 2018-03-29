//
//  UIColorHexValueTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 3/29/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//
import XCTest

@testable import SnowChat

class TestHexColors: XCTestCase {
    
    func testNormalHex() {
        let hex = "#FF00FF"
        
        let color = UIColor(hexValue: hex)
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssert(red == 1.0 && green == 0 && blue == 1.0 && alpha == 1.0)
    }

    func testShortHex() {
        let hex = "#F0F"
        
        let color = UIColor(hexValue: hex)
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssert(red == 1.0 && green == 0 && blue == 1.0 && alpha == 1.0)
    }
}
