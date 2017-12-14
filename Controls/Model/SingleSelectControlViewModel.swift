//
//  SingleSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class SingleSelectControlViewModel: PickerControlViewModel, ValueRepresentable {
    
    let id: String
    
    let label: String
    
    let isRequired: Bool
    
    let isMultiSelect: Bool
    
    var items = [PickerItem]()
    
    var type: ControlType {
        return .multiSelect
    }
    
    init(id: String, label: String, required: Bool, items: [PickerItem]) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.isMultiSelect = false
        self.items = items
        
        if !required {
            self.items.append(PickerItem.skipItem())
        }
    }
    
    // MARK: - ValueRepresentable
    
    var resultValue: String? {
        guard let selectedItem = selectedItem, selectedItem.type != .skip else {
            return nil
        }
        
        // is Yes selected?
        return selectedItem.value as? String
    }
}
