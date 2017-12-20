//
//  PickerControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

protocol PickerControlViewModel: ControlViewModel {
    
    // can user select mutliple items?
    var isMultiSelect: Bool { get }
    
    // collection of item models
    var items: [PickerItem] { get }
    
    var selectedItems: [PickerItem] { get }
    
    var selectedItem: PickerItem? { get }
    
    func select(itemAt index: Int)
}

// MARK: - Items selection: provides default implementation for selecting items
extension PickerControlViewModel {
    
    var selectedItems: [PickerItem] {
        let values = items.filter({ $0.isSelected })
        return values
    }
    
    var selectedItem: PickerItem? {
        return selectedItems.first
    }
    
    func select(itemAt index: Int) {
        // clear out all the items first
        items.forEach({ $0.isSelected = false })
        let item = items[index]
        item.isSelected = true
    }
}
