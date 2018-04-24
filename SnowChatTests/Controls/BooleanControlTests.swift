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
        let model = BooleanControlViewModel(id: "123", required: true, messageDate: Date())
        let booleanControl = BooleanControl(model: model)
        XCTAssert(booleanControl.style == .list)
    }
    
    func testBooleanControlValueSetting() {
        let model = BooleanControlViewModel(id: "123", required: true, messageDate: Date())
        
        // Select No
        model.selectItem(at: 0)
        var result = model.resultValue
        XCTAssert(result! == true)

        XCTAssert(model.selectedItems.count != 0)
        var selectedItems = model.selectedItems
        XCTAssert(selectedItems.count == 1)

        // Select Yes
        model.selectItem(at: 1)
        result = (model.resultValue)!
        XCTAssert(result == false)

        XCTAssert(model.selectedItems.count != 0)
        selectedItems = model.selectedItems
        XCTAssert(selectedItems.count == 1)
    }
    
    // Required = false will introduce a "Skip" button to the picker
    func testNonRequiredBooleanControlValueHasSkipItem() {
        let model = BooleanControlViewModel(id: "123", required: false, messageDate: Date())
        
        // Select Skip!
        model.selectItem(at: 2)
        let result = model.resultValue
        XCTAssert(result == nil)
    }
    
    func testBooleanMultiSelectVar() {
        let model = BooleanControlViewModel(id: "123", required: true, messageDate: Date())
        XCTAssert(model.isMultiSelect == false)
    }
    
    func testBooleanReturnValue() {
        // result value coming from server set to true
        var model = BooleanControlViewModel(id: "123", required: true, resultValue: true, messageDate: Date())
        var result = model.resultValue
        XCTAssert(result! == true)
        
        var displayValue = model.displayValue
        XCTAssert(displayValue! == "Yes")
        
        // result value set to false
        model = BooleanControlViewModel(id: "123", required: true, resultValue: false, messageDate: Date())
        result = model.resultValue
        XCTAssert(result! == false)
        
        displayValue = model.displayValue
        XCTAssert(displayValue! == "No")
    }
}
