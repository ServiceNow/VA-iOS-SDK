//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class BooleanControlViewModel: PickerControlViewModel {

    let id: String
    
    let title: String
    
    let isRequired: Bool
    
    let isMultiSelect: Bool
    
    let items: [SelectableItemViewModel]
    
    let type: CBControlType = .boolean
    
    var value: Bool {
        return selectedItems?.first?.isSelected ?? false
    }
    
    required convenience init(id: String, title: String, required: Bool) {
        let items = [SelectableItemViewModel(title: "Yes"), SelectableItemViewModel(title: "No")]
        self.init(id: id, title: title, required: required, items: items)
    }
    
    required init(id: String, title: String, required: Bool, items: [SelectableItemViewModel], multiSelect: Bool = false) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.isMultiSelect = multiSelect
        self.items = items
    }
}
