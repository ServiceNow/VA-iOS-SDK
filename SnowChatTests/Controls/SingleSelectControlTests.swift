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
        
        self.singleSelectItems = [PickerItem(label: "Item 1"), PickerItem(label: "Item 2"), PickerItem(label: "Item 3"), PickerItem(label: "Item 4")]
    }
    
    func testSingleSelectVCDefaultPresentationStyle() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, items: singleSelectItems!)
        let singleSelect = SingleSelectControl(model: model)
        XCTAssert(singleSelect.style == .inline)
    }
    
    func testSingleSelectValueItems() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, items: singleSelectItems!)
        
        model.select(itemAt: 0)
        XCTAssert(model.selectedItems.count == 1)
        
        model.select(itemAt: 1)
        XCTAssert(model.selectedItems.count == 1)
    }
    
    func testBooleanMultiSelectVar() {
        let model = SingleSelectControlViewModel(id: "123", label: "?", required: true, items: singleSelectItems!)
        XCTAssert(model.isMultiSelect == false)
    }
}
