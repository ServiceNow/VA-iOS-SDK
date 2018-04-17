//
//  MultiSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class MultiSelectControlViewModel: PickerControlViewModel, ValueRepresentable {
    
    let isMultiSelect: Bool = true
    
    let isRequired: Bool
    
    var items = [PickerItem]()
    
    let label: String?
    
    let id: String
    
    let type: ControlType = .multiSelect
    
    let messageDate: Date?
    
    init(id: String, label: String? = nil, required: Bool, items: [PickerItem], resultValue: [String]? = nil, messageDate: Date) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.items = items
        self.messageDate = messageDate
        
        if !required {
            self.items.append(PickerItem.skipItem())
        }
        selectItems(withValues: resultValue)
    }
    
    func selectItem(at index: Int) {
        let item = items[index]
        
        // if .skip item is selected - unselect all other items
        if item.type == .skip {
            items.forEach({ $0.isSelected = false })
        }
        
        item.isSelected = !item.isSelected
    }
    
    private func selectItems(withValues values: [String]?) {
        items.forEach({ $0.isSelected = false })
        
        if let values = values {
            items.filter({ values.contains($0.value) }).forEach({ $0.isSelected = true })
        }
    }
    
    // MARK: - ValueRepresentable
    
    var resultValue: [String]? {
        guard selectedItems.count != 0, selectedItems.first?.type != .skip else {
            return nil
        }
        
        // Array of selected values
        let values = selectedItems.map({ $0.value })
        return values
    }
    
    var displayValue: String? {
        return resultValue?.joinedWithCommaSeparator()
    }
}
