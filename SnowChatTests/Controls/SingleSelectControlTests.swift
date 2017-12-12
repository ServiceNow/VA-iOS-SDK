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
    
    private var singleSelectItems: [SelectableItemViewModel]?
    
    override func setUp() {
        super.setUp()
        
        self.singleSelectItems = [SelectableItemViewModel(title: "Item 1"), SelectableItemViewModel(title: "Item 2"), SelectableItemViewModel(title: "Item 3"), SelectableItemViewModel(title: "Item 4")]
    }
    
    func testSingleSelectVCDefaultPresentationStyle() {
        let model = SingleSelectControlViewModel(id: "123", title: "?", required: true, items: singleSelectItems!)
        let singleSelect = SingleSelectControl(model: model)
        XCTAssert(singleSelect.style == .inline)
    }
    
    func testSingleSelectValueItems() {
        let model = SingleSelectControlViewModel(id: "123", title: "?", required: true, items: singleSelectItems!)
        XCTAssert(model.value == nil)
        
        model.select(itemAt: 0)
        XCTAssert(model.selectedItems.count == 1)
        
        model.select(itemAt: 1)
        XCTAssert(model.selectedItems.count == 1)
    }
    
    func testBooleanMultiSelectVar() {
        let model = SingleSelectControlViewModel(id: "123", title: "?", required: true, items: singleSelectItems!)
        XCTAssert(model.isMultiSelect == false)
    }
}
