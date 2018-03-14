//
//  PickerItem.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// Used in all picker types but carousel

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
        let localizedLabel = NSLocalizedString("Skip", comment: "Skip item")
        let item = PickerItem(type: .skip, label: localizedLabel, value: "Skip")
        return item
    }
    
    static func yesItem() -> PickerItem {
        let localizedLabel = NSLocalizedString("Yes", comment: "Yes item")
        let item = PickerItem(type: .yes, label: localizedLabel, value: "Yes")
        return item
    }
    
    static func noItem() -> PickerItem {
        let localizedLabel = NSLocalizedString("No", comment: "No item")
        let item = PickerItem(type: .no, label: localizedLabel, value: "No")
        return item
    }
    
    static func takePhotoItem() -> PickerItem {
        let localizedLabel = NSLocalizedString("Take Photo", comment: "Take Photo item")
        let item = PickerItem(type: .takePhoto, label: localizedLabel, value: "Take Photo")
        return item
    }
    
    static func photoLibraryItem() -> PickerItem {
        let localizedLabel = NSLocalizedString("Photo Library", comment: "Photo Library item")
        let item = PickerItem(type: .photoLibrary, label: localizedLabel, value: "Photo Library")
        return item
    }
}
