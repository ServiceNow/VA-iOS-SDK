//
//  MultiselectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class MultiselectControlViewModel: PickerControlViewModel {
    
    var isMultiselect: Bool = true
    
    let isRequired: Bool
    
    var items: [SelectableItemViewModel]?
    
    let title: String
    
    let id: String
    
    required init(id: String, title: String, required: Bool = true) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.items = [SelectableItemViewModel(title: "Item 1"), SelectableItemViewModel(title: "Item 2"), SelectableItemViewModel(title: "Item 3"), SelectableItemViewModel(title: "Item 4")]
    }
}
