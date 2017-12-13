//
//  PickerControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//


// base class for item model
class SelectableItemViewModel: ControlViewModel {
    
    var value: ControlValue?
    
    let id: String
    
    let label: String
    
    let isRequired: Bool = true
    
    var isSelected: Bool = false
    
    var type: CBControlType = .unknown
    
    init(id: String = "selectable_item", label: String, value: ControlValue = .null) {
        self.label = label
        self.value = value
        self.id = id
    }
    
    static func skipItem() -> SelectableItemViewModel {
        let item = SelectableItemViewModel(label: "Skip")
        return item
    }
}

protocol PickerControlViewModel: ControlViewModel {
    
    // can user select mutliple items?
    var isMultiSelect: Bool { get }
    
    // collection of item models
    var items: [SelectableItemViewModel] { get }
    
    var selectedItems: [SelectableItemViewModel] { get }
    
    var selectedItem: SelectableItemViewModel? { get }
    
    func select(itemAt index: Int)
    
//    init(id: String, title: String, required: Bool, items: [SelectableItemViewModel], multiSelect: Bool)
}

// Provides default implementation for displayValues and selectedItems
extension PickerControlViewModel {
    
    var selectedItems: [SelectableItemViewModel] {
        let values = items.filter({ $0.isSelected })
        return values
    }
    
    var selectedItem: SelectableItemViewModel? {
        return selectedItems.first
    }
}
