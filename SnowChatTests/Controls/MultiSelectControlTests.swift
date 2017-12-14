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
        
        self.multiSelectItems = [PickerItem(label: "Item 1"), PickerItem(label: "Item 2"), PickerItem(label: "Item 3"), PickerItem(label: "Item 4")]
    }
    
    func testMultiSelectPickerVCDefaultPresentationStyle() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, items: multiSelectItems!)
        let multiSelectPicker = MultiSelectControl(model: model)
    
        XCTAssert(multiSelectPicker.style == .inline)
    }

    func testMultiSelectSelection() {
        let model = MultiSelectControlViewModel(id: "123", label: "Choice", required: true, items: multiSelectItems!)
        
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
}
