//
//  MultiSelectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class MultiSelectControlViewModel: PickerControlViewModel {
    
    let isMultiSelect: Bool 
    
    let isRequired: Bool
    
    var items: [SelectableItemViewModel]
    
    let title: String
    
    let id: String
    
    var type: CBControlType = .multiSelect
    
    required convenience init(id: String, title: String, required: Bool, items: [SelectableItemViewModel]) {
        self.init(id: id, title: title, required: required, items: items)
    }
    
    required init(id: String, title: String, required: Bool, items: [SelectableItemViewModel], multiSelect: Bool = true) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.isMultiSelect = true
        self.items = items
    }
}
