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
        case takePhoto
        case photoLibrary
        case custom
    }
    
    let label: String?
    
    var value: String
    
    var isSelected: Bool = false
    
    let type: ItemType
    
    init(type: ItemType = .custom, label: String? = nil, value: String) {
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
    
    static func takePhotoItem() -> PickerItem {
        let item = PickerItem(type: .takePhoto, label: "Take Photo", value: "Take Photo")
        return item
    }
    
    static func photoLibraryItem() -> PickerItem {
        let item = PickerItem(type: .photoLibrary, label: "Photo Library", value: "Photo Library")
        return item
    }
}
