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
    
    let type: ControlType = .multiSelect
    
    var direction: ControlDirection
    
    init(id: String, label: String, required: Bool, direction: ControlDirection, items: [PickerItem], resultValue: String? = nil) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.isMultiSelect = false
        self.items = items
        self.direction = direction
        
        if !required {
            self.items.append(PickerItem.skipItem())
        }
        
        selectItem(withValue: resultValue)
    }
    
    private func selectItem(withValue value: String?) {
        guard let value = value else {
            return
        }
        
        let item = items.first(where: { $0.value == value })
        item?.isSelected = true
    }
    
    // MARK: - ValueRepresentable
    
    var resultValue: String? {
        guard let selectedItem = selectedItem, selectedItem.type != .skip else {
            return nil
        }
        
        return selectedItem.value
    }
    
    var displayValue: String? {
        return resultValue
    }
}
