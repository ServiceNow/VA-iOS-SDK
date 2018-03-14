//
//  MultiSelectControlTests.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class MultiSelectControlTests: XCTestCase {
    
    private var multiSelectItems: [PickerItem]?
    
    override func setUp() {
        super.setUp()
        
        self.multiSelectItems = [PickerItem(label: "Item 1", value: "1"), PickerItem(label: "Item 2", value: "2"), PickerItem(label: "Item 3", value: "3"), PickerItem(label: "Item 4", value: "4")]
    }
    
    func testMultiSelectPickerVCDefaultPresentationStyle() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, items: multiSelectItems!)
        let multiSelectPicker = MultiSelectControl(model: model)
    
        XCTAssert(multiSelectPicker.style == .regular)
    }

    func testMultiSelectSelectionWithRequiredTrue() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, items: multiSelectItems!)
        
        XCTAssert(model.selectedItems.count == 0)
        model.selectItem(at: 0)
        
        let selectedItems = model.selectedItems
        XCTAssert(selectedItems.count == 1)
        
        model.selectItem(at: 1)
        model.selectItem(at: 2)
        XCTAssert(model.selectedItems.count == 3)
        
        // deselect item
        model.selectItem(at: 2)
        XCTAssert(model.selectedItems.count == 2)
    }
    
    func testResultWithRequiredTrue() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, items: multiSelectItems!)
        model.selectItem(at: 0)
        model.selectItem(at: 1)
        
        let result = model.resultValue
        XCTAssert(result![0] == "1")
        XCTAssert(result![1] == "2")
    }
    
    func testMultiSelectSelectionWithRequiredFalse() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: false, items: multiSelectItems!)
        model.selectItem(at: 4)
        XCTAssert(model.selectedItem!.type == .skip)
    }
    
    func testResultWithRequiredFalse() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: false, items: multiSelectItems!)
        model.selectItem(at: 0)
        model.selectItem(at: 1)
        
        var result = model.resultValue
        XCTAssert(result![0] == "1")
        XCTAssert(result![1] == "2")
        
        // select Skip
        model.selectItem(at: 4)
        result = model.resultValue
        XCTAssertNil(result)
    }
    
    func testMultiSelectReturnValue() {
        var model = MultiSelectControlViewModel(id: "123", label: "Choice", required: false, items: multiSelectItems!, resultValue: ["1", "3"])
        var result = model.resultValue
        XCTAssert(result! == ["1", "3"])
        
        var displayValue = model.displayValue
        XCTAssert(displayValue! == "1, 3")
        
        // try selecting item that is not part of model
        model = MultiSelectControlViewModel(id: "123", label: "Choice", required: false, items: multiSelectItems!, resultValue: ["1", "5"])
        
        result = model.resultValue
        XCTAssert(result! == ["1"])
        
        displayValue = model.displayValue
        XCTAssert(displayValue! == "1")
    }
}
