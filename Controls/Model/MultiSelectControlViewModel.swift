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
    
    let label: String
    
    let id: String
    
    let type: ControlType = .multiSelect
    
    var direction: ControlDirection
    
    init(id: String, label: String, required: Bool, direction: ControlDirection, items: [PickerItem], resultValue: [String]? = nil) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.items = items
        self.direction = direction
        self.resultValue = resultValue
        
        if !required {
            self.items.append(PickerItem.skipItem())
        }
    }
    
    func select(itemAt index: Int) {
        let item = items[index]
        
        // if .skip item is selected - unselect all other items
        if item.type == .skip {
            items.forEach({ $0.isSelected = false })
        }
        
        item.isSelected = !item.isSelected
    }
    
    // MARK: - ValueRepresentable
    
    var resultValue: [String]? {
        set {
            // select items whose value matches resultValues
            if let resultValue = resultValue {
                items.filter({ resultValue.contains($0.value) }).forEach({ $0.isSelected = true })
            }
        }
        get {
            guard selectedItems.count != 0, selectedItems.first?.type != .skip else {
                return nil
            }
            
            // Array of selected values
            let values = selectedItems.map({ $0.value })
            return values
        }
    }
    
    var displayValue: String? {
        return resultValue?.joined(separator: ", ")
    }
}

extension Array {
    func contains<T : Equatable>(_ object: T) -> Bool {
        return self.filter({$0 as? T == object}).count > 0
    }
}
