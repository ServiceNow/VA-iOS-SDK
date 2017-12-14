//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class BooleanControlViewModel: PickerControlViewModel, Resultable {
    
    let id: String
    
    let label: String
    
    let isRequired: Bool
    
    let isMultiSelect: Bool
    
    var items = [PickerItem]()

    var type: ControlType {
        return .boolean
    }
    
    init(id: String, label: String, required: Bool) {
        let items = [PickerItem(label: "Yes"), PickerItem(label: "No")]
        self.id = id
        self.label = label
        self.isRequired = required
        self.isMultiSelect = false
        self.items = items
        
        if required {
            self.items.append(PickerItem.skipItem())
        }
    }
    
    var value: Bool? {
        guard let selectedItem = selectedItem else {
            return nil
        }

        // is Yes selected?
        let isSelected = selectedItem === items[0]
        return isSelected
    }
}
