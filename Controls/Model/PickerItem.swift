//
//  PickerItem.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// class for picker item model
class PickerItem {
    
    enum ItemType {
        case yes
        case no
        case skip
        case custom
    }
    
    let label: String
    
    var value: Any
    
    var isSelected: Bool = false
    
    let type: ItemType
    
    init(type: ItemType = .custom, label: String, value: Any) {
        self.label = label
        self.value = value
        self.type = type
    }
}

// MARK: - PickerItem Utils

extension PickerItem {
    
    static func skipItem() -> PickerItem {
        let item = PickerItem(type: .skip, label: "Skip", value: "Skip")
        return item
    }
    
    static func yesItem() -> PickerItem {
        let item = PickerItem(type: .yes, label: "Yes", value: "Yes")
        return item
    }
    
    static func noItem() -> PickerItem {
        let item = PickerItem(type: .no, label: "No", value: "No")
        return item
    }
}
