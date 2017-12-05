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
    
    var isMultiselect: Bool = false
    
    var items: [SelectableItemViewModel]?
    
    required init(id: String, title: String, required: Bool = true) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.items = [SelectableItemViewModel(title: "Yes"), SelectableItemViewModel(title: "No")]
    }
}
