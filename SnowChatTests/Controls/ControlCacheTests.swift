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
    let apiManager = APIManager(instance: ServerInstance(instanceURL: URL(fileURLWithPath: "./Home")))
    
    private var controlCache = ControlCache()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        controlCache.removeAll()
    }
    
    func testReuseTextControl() {
        let firstTextControlModel = TextControlViewModel(id: "first_text_control", value: "Sample text", messageDate: nil)
        let firstTextControl = controlCache.control(forModel: firstTextControlModel, forResourceProvider: apiManager)
        XCTAssert(firstTextControl.model.id == "first_text_control")
        
        controlCache.cacheControl(firstTextControl)
        let secondTextControlModel = TextControlViewModel(id: "second_text_control", value: "Another sample text", messageDate: nil)
        let secondTextControl = controlCache.control(forModel: secondTextControlModel, forResourceProvider: apiManager)
        
        // Compare objects' addresses
        XCTAssert(firstTextControl === secondTextControl)
        XCTAssert(firstTextControlModel !== secondTextControlModel)
        XCTAssert(secondTextControl.model.id == "second_text_control")
        
        // This should create new control since there nothing to reuse
        let thirdTextControl = controlCache.control(forModel: firstTextControlModel, forResourceProvider: apiManager)
        XCTAssert(secondTextControl !== thirdTextControl)
    }
    
    func testReuseTextAndBooleanControl() {
        let firstTextControlModel = TextControlViewModel(id: "first_text_control", value: "Sample text", messageDate: nil)
        let booleanControlModel = BooleanControlViewModel(id: "boolean_control", required: true, messageDate: Date())
        let booleanControl = controlCache.control(forModel: booleanControlModel, forResourceProvider: apiManager)
        let textControl = controlCache.control(forModel: firstTextControlModel, forResourceProvider: apiManager)
        
        // Nothing to reuse yet so we should get new TextControl
        let secondTextControlModel = TextControlViewModel(id: "second_text_control", value: "Sample text", messageDate: nil)
        let secondTextControl = controlCache.control(forModel: secondTextControlModel, forResourceProvider: apiManager)
        XCTAssert(secondTextControl !== textControl)
        
        // Prepare for reuse boolean control
        controlCache.cacheControl(booleanControl)
        let thirdTextControlModel = TextControlViewModel(id: "third_text_control", value: "Sample text", messageDate: nil)
        let control = controlCache.control(forModel: thirdTextControlModel, forResourceProvider: apiManager)
        
        // Make sure cache is not returning wrong control type
        XCTAssert(control !== booleanControl)
    }
}
