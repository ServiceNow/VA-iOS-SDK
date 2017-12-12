//
//  SingleSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class SingleSelectControlViewModel: PickerControlViewModel {
    
    let id: String
    
    let title: String
    
    let isRequired: Bool
    
    let isMultiSelect: Bool
    
    let items: [SelectableItemViewModel]
    
    var type: CBControlType {
        return .multiSelect
    }
    
    var value: Bool? {
        guard let selectedItem = selectedItem else {
            return nil
        }
        
        // is Yes selected?
        return selectedItem === items[0]
    }
    
    init(id: String, title: String, required: Bool, items: [SelectableItemViewModel]) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.isMultiSelect = false
        self.items = items
    }
    
    func select(itemAt index: Int) {
        // clear out all the items first
        items.forEach({ $0.isSelected = false })
        let item = items[index]
        item.isSelected = true
    }
    
}
