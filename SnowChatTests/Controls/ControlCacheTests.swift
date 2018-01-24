//
//  ControlCacheTests.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 1/17/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class ControlCacheTests: XCTestCase {
    
    private var controlCache = ControlCache()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        controlCache.removeAll()
    }
    
    func testReuseTextControl() {
        let firstTextControlModel = TextControlViewModel(id: "first_text_control", value: "Sample text")
        let firstTextControl = controlCache.control(forModel: firstTextControlModel)
        XCTAssert(firstTextControl.model.id == "first_text_control")
        
        controlCache.cacheControl(forModel: firstTextControlModel)
        let secondTextControlModel = TextControlViewModel(id: "second_text_control", value: "Another sample text")
        let secondTextControl = controlCache.control(forModel: secondTextControlModel)
        
        // Compare objects' addresses
        XCTAssert(firstTextControl === secondTextControl)
        XCTAssert(firstTextControlModel !== secondTextControlModel)
        XCTAssert(secondTextControl.model.id == "second_text_control")
        
        // This should create new control since there nothing to reuse
        let thirdTextControl = controlCache.control(forModel: firstTextControlModel)
        XCTAssert(secondTextControl !== thirdTextControl)
    }
    
    func testReuseTextAndBooleanControl() {
        let firstTextControlModel = TextControlViewModel(id: "first_text_control", value: "Sample text")
        let booleanControlModel = BooleanControlViewModel(id: "boolean_control", required: true)
        let booleanControl = controlCache.control(forModel: booleanControlModel)
        let textControl = controlCache.control(forModel: firstTextControlModel)
        
        // Nothing to reuse yet so we should get new TextControl
        let secondTextControlModel = TextControlViewModel(id: "second_text_control", value: "Sample text")
        let secondTextControl = controlCache.control(forModel: secondTextControlModel)
        XCTAssert(secondTextControl !== textControl)
        
        // Prepare for reuse boolean control
        controlCache.cacheControl(forModel: booleanControlModel)
        let thirdTextControlModel = TextControlViewModel(id: "third_text_control", value: "Sample text")
        let control = controlCache.control(forModel: thirdTextControlModel)
        
        // Make sure cache is not returning wrong control type
        XCTAssert(control !== booleanControl)
    }
}
