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
        let hexNoPrefix = "FF00FF"
        
        guard let color = UIColor(css: hex),
              let colorNoPrefix = UIColor(css: hexNoPrefix) else {
                XCTAssertTrue(false)
                return
        }
        
        
        XCTAssertEqual(color, colorNoPrefix)
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssert(red == 1.0 && green == 0 && blue == 1.0 && alpha == 1.0)
    }

    func testShortHex() {
        let hex = "#F0F"
        
        guard let color = UIColor(css: hex) else {
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
    
    func testMalformedHex() {
        let hex = "#F0F0"
        
        guard let color = UIColor(css: hex) else {
            XCTAssertTrue(false)
            return
        }

        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // make sure it is something
        XCTAssert(red + green + blue > 1.0 && alpha == 1.0)
    }
    
}
