//
//  PickerControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// base class for item model
class SelectableItemViewModel: ControlViewModel {
    
    let id: String
    
    let title: String
    
    let isRequired: Bool
    
    var isSelected: Bool = false
    
    var displayValue: String? {
        return title
    }
    
    var type: Control {
        return .selectableItem
    }
    
    required init(id: String = "selectable_item", title: String, required: Bool = true) {
        self.title = title
        self.id = id
        self.isRequired = required
    }
}

protocol PickerControlViewModel: ControlViewModel {
    
    // can user select mutliple items?
    var isMultiselect: Bool { get set }
    
    // collection of item models
    var items: [SelectableItemViewModel]? { get set }
    
    // represents items as a string
    var displayValues: [String?]? { get }
    
    var selectedItems: [SelectableItemViewModel]? { get }
}

// Provides default implementation for displayValues and selectedItems
extension PickerControlViewModel {
    
    var displayValues: [String?]? {
        let values = items?.map({ $0.displayValue })
        return values
    }
    
    var selectedItems: [SelectableItemViewModel]? {
        let values = items?.filter({ $0.isSelected })
        return values
    }
}
