//
//  SingleSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class SingleSelectControlViewModel: PickerControlViewModel {
    
    var value: ControlValue? {
        return nil
    }
    
    let id: String
    
    let label: String
    
    let isRequired: Bool
    
    let isMultiSelect: Bool
    
    var items = [SelectableItemViewModel]()
    
    var type: CBControlType {
        return .multiSelect
    }
    
    init(id: String, label: String, required: Bool, items: [SelectableItemViewModel]) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.isMultiSelect = false
        self.items = items
        
        if required {
            self.items.append(SelectableItemViewModel.skipItem())
        }
    }
    
    func select(itemAt index: Int) {
        // clear out all the items first
        items.forEach({ $0.isSelected = false })
        let item = items[index]
        item.isSelected = true
    }
    
}
