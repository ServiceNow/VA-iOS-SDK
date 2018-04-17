//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class BooleanControlViewModel: PickerControlViewModel, ValueRepresentable {
    
    let id: String
    
    let label: String?
    
    let isRequired: Bool
    
    let isMultiSelect: Bool
    
    var items = [PickerItem]()

    let type: ControlType = .boolean
    
    let messageDate: Date?
    
    init(id: String, label: String? = nil, required: Bool, resultValue: Bool? = nil, messageDate: Date) {
        let items = [PickerItem.yesItem(), PickerItem.noItem()]
        self.id = id
        self.label = label
        self.isRequired = required
        self.isMultiSelect = false
        self.items = items
        self.messageDate = messageDate
        
        if !required {
            self.items.append(PickerItem.skipItem())
        }
        selectItemForResultValue(resultValue)
    }
    
    // MARK: - ValueRepresentable
    
    private func selectItemForResultValue(_ value: Bool?) {
        guard let value = value else {
            return
        }
        
        let item: PickerItem?
        if value == true {
            item = items.first(where: { $0.type == .yes })
        } else {
            item = items.first(where: { $0.type == .no })
        }
        
        item?.isSelected = true
    }
    
    var resultValue: Bool? {
        guard let selectedItem = selectedItem, selectedItem.type != .skip else {
            return nil
        }
        
        // is Yes selected?
        return selectedItem.type == .yes
    }
    
    var displayValue: String? {
        return resultValue?.chatDescription
    }
}

// FIXME: little helper to return Yes/No based on bool value. Probably might be done different way. Also needs localization.
extension Bool {
    public var chatDescription: String {
        return self ? "Yes" : "No"
    }
}
