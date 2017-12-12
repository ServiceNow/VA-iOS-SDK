//
//  MultiSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class MultiSelectControlViewModel: PickerControlViewModel {
    
    let isMultiSelect: Bool 
    
    let isRequired: Bool
    
    let items: [SelectableItemViewModel]
    
    let title: String
    
    let id: String
    
    let type: CBControlType = .multiSelect
    
    init(id: String, title: String, required: Bool, items: [SelectableItemViewModel]) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.isMultiSelect = true
        self.items = items
    }
    
    func select(itemAt index: Int) {
        let item = items[index]
        item.isSelected = !item.isSelected
    }
}
