//
//  BooleanControlTests.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class BooleanControlTests: XCTestCase {
    
    func testBooleanPickerVCDefaultPresentationStyle() {
        let model = BooleanControlViewModel(id: "123", label: "?", required: true, direction: .inbound)
        let booleanControl = BooleanControl(model: model)
        XCTAssert(booleanControl.style == .inline)
    }
    
    func testBooleanControlValueSetting() {
        let model = BooleanControlViewModel(id: "123", label: "?", required: true, direction: .inbound)
        
        // Select No
        model.select(itemAt: 0)
        var result = model.resultValue
        XCTAssert(result! == true)

        XCTAssert(model.selectedItems.count != 0)
        var selectedItems = model.selectedItems
        XCTAssert(selectedItems.count == 1)

        // Select Yes
        model.select(itemAt: 1)
        result = (model.resultValue)!
        XCTAssert(result == false)

        XCTAssert(model.selectedItems.count != 0)
        selectedItems = model.selectedItems
        XCTAssert(selectedItems.count == 1)
    }
    
    // Required = false will introduce a "Skip" button to the picker
    func testNonRequiredBooleanControlValueHasSkipItem() {
        let model = BooleanControlViewModel(id: "123", label: "?", required: false, direction: .inbound)
        
        // Select Skip!
        model.select(itemAt: 2)
        let result = model.resultValue
        XCTAssert(result == nil)
    }
    
    func testBooleanMultiSelectVar() {
        let model = BooleanControlViewModel(id: "123", label: "?", required: true, direction: .inbound)
        XCTAssert(model.isMultiSelect == false)
    }
}