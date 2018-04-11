//
//  UIColorHexValueTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 3/29/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//
import XCTest

@testable import SnowChat

class TestCSSColors: XCTestCase {
    
    func testNormalHex() {
        let hex = "#FF00FF"
        
        guard let color = UIColor.now_color(withCSS: hex) else {
                XCTAssertTrue(false)
                return
        }
    
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssert(red == 1.0 && green == 0 && blue == 1.0 && alpha == 1.0)
    }

    func testShortHex() {
        let hex = "#F0F"
        
        guard let color = UIColor.now_color(withCSS: hex) else {
            XCTAssertTrue(false)
            return
        }
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssert(red == 1.0 && green == 0 && blue == 1.0 && alpha == 1.0)
    }
    
    func testHexNoPrefix() {
        let hex = "F0F0F0"
        
        let color = UIColor.now_color(withCSS: hex)
        XCTAssertNil(color)
    }

    func testNamedString() {
        let value = "bisque"
        
        guard let color = UIColor.now_color(withCSS: value) else {
            XCTAssertTrue(false)
            return
        }

        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssert(red + green + blue > 0.0 && alpha == 1.0)
    }

    func testRandomString() {
        let value = "WeAreDEVO!"
        
        let color = UIColor.now_color(withCSS: value)
        XCTAssertNil(color)
    }    
}
