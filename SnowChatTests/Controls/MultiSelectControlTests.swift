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
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, direction: .inbound, items: multiSelectItems!)
        let multiSelectPicker = MultiSelectControl(model: model)
    
        XCTAssert(multiSelectPicker.style == .inline)
    }

    func testMultiSelectSelectionWithRequiredTrue() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, direction: .inbound, items: multiSelectItems!)
        
        XCTAssert(model.selectedItems.count == 0)
        model.select(itemAt: 0)
        
        let selectedItems = model.selectedItems
        XCTAssert(selectedItems.count == 1)
        
        model.select(itemAt: 1)
        model.select(itemAt: 2)
        XCTAssert(model.selectedItems.count == 3)
        
        // deselect item
        model.select(itemAt: 2)
        XCTAssert(model.selectedItems.count == 2)
    }
    
    func testResultWithRequiredTrue() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, direction: .inbound, items: multiSelectItems!)
        model.select(itemAt: 0)
        model.select(itemAt: 1)
        
        let result = model.resultValue
        XCTAssert(result![0] == "1")
        XCTAssert(result![1] == "2")
    }
    
    func testMultiSelectSelectionWithRequiredFalse() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: false, direction: .inbound, items: multiSelectItems!)
        model.select(itemAt: 4)
        XCTAssert(model.selectedItem!.type == .skip)
    }
    
    func testResultWithRequiredFalse() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: false, direction: .inbound, items: multiSelectItems!)
        model.select(itemAt: 0)
        model.select(itemAt: 1)
        
        var result = model.resultValue
        XCTAssert(result![0] == "1")
        XCTAssert(result![1] == "2")
        
        // select Skip
        model.select(itemAt: 4)
        result = model.resultValue
        XCTAssertNil(result)
    }
}
