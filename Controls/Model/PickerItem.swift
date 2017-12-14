//
//  PickerItem.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// class for picker item model
class PickerItem {
    
    let label: String
    
    var isSelected: Bool = false
    
    var value: AnyObject?
    
    init(label: String, value: AnyObject? = nil) {
        self.label = label
        self.value = value
    }
    
    static func skipItem() -> PickerItem {
        let item = PickerItem(label: "Skip")
        return item
    }
}
