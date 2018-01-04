//
//  SingleSelectControlTests.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class SingleSelectControlTests: XCTestCase {
    
    private var singleSelectItems: [PickerItem]?
    
    override func setUp() {
        super.setUp()
        
        self.singleSelectItems = [PickerItem(label: "Item 1", value: "1"), PickerItem(label: "Item 2", value: "2"), PickerItem(label: "Item 3", value: "3"), PickerItem(label: "Item 4", value: "4")]
    }
    
    func testSingleSelectVCDefaultPresentationStyle() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, direction: .inbound, items: singleSelectItems!)
        let singleSelect = SingleSelectControl(model: model)
        XCTAssert(singleSelect.style == .inline)
    }
    
    func testSingleSelectValueItemsWithRequiredTrue() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, direction: .inbound, items: singleSelectItems!)
        
        model.selectItem(at: 0)
        XCTAssert(model.selectedItems.count == 1)
        
        model.selectItem(at: 1)
        XCTAssert(model.selectedItems.count == 1)
    }
    
    func testSingleSelectValueItemsWithRequiredFalse() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: false, direction: .inbound, items: singleSelectItems!)
        
        model.selectItem(at: 0)
        XCTAssert(model.selectedItems.count == 1)
        
        model.selectItem(at: 1)
        XCTAssert(model.selectedItems.count == 1)
        
        model.selectItem(at: 4)
        XCTAssert(model.selectedItem!.type == .skip)
    }
    
    func testResultTrue() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, direction: .inbound, items: singleSelectItems!)
        
        model.selectItem(at: 0)
        var result = model.resultValue
        XCTAssert(result! == "1")
        
        model.selectItem(at: 1)
        result = model.resultValue
        XCTAssert(result! == "2")
    }
    
    func testResultFalse() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: false, direction: .inbound, items: singleSelectItems!)
        
        model.selectItem(at: 0)
        var result = model.resultValue
        XCTAssert(result! == "1")
        
        model.selectItem(at: 1)
        result = model.resultValue
        XCTAssert(result! == "2")
        
        // select .skip button
        model.selectItem(at: 4)
        result = model.resultValue
        XCTAssertNil(result)
    }
    
    func testSingleSelectMultiSelectVar() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, direction: .inbound, items: singleSelectItems!)
        XCTAssert(model.isMultiSelect == false)
    }
    
    func testSingleSelectReturnValue() {
        // result value coming from server set to true
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, direction: .inbound, items: singleSelectItems!, resultValue: "1")
        let result = model.resultValue
        XCTAssert(result! == "1")
        
        let displayValue = model.displayValue
        XCTAssert(displayValue! == "1")
    }
    
    func testSingleSelectReturnValueNotPresentedInModel() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, direction: .inbound, items: singleSelectItems!, resultValue: "5")
        let result = model.resultValue
        XCTAssertNil(result)
        
        let displayValue = model.displayValue
        XCTAssertNil(displayValue)
    }
}
