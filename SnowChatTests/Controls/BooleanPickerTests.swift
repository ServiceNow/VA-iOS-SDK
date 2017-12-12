//
//  BooleanPickerTests.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class BooleanPickerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testBooleanPickerDefaultPresentationStyle() {
        let model = BooleanControlViewModel(id: "123", title: "", required: true)
        let booleanControl = BooleanPickerControl(model: model)
        XCTAssert(booleanControl.style == .inline)
    }
    
    func testBooleanPickerItems() {
        
    }
}
