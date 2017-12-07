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
    
    var items: [SelectableItemViewModel]?
    
    let title: String
    
    let id: String
    
    var type: CBControlType = .multiSelect
    
    required init(id: String, title: String, required: Bool, items: [SelectableItemViewModel], multiSelect: Bool = true) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.isMultiSelect = multiSelect
        self.items = items
    }
}
