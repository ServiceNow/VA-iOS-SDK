//
//  MultiSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class MultiSelectControlViewModel: PickerControlViewModel {
    
    let isMultiSelect: Bool = true
    
    let isRequired: Bool
    
    let items: [PickerItem]
    
    let label: String
    
    let id: String
    
    let type: ControlType = .multiSelect
    
    init(id: String, label: String, required: Bool, items: [PickerItem]) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.items = items
    }
    
    func select(itemAt index: Int) {
        let item = items[index]
        item.isSelected = !item.isSelected
    }
}
