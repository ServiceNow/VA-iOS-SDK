//
//  MultiselectControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class MultiselectControlViewModel: PickerControlViewModel {
    
    var isMultiselect: Bool
    
    var isRequired: Bool?
    
    var items: [SelectableItemViewModel]?
    
    var title: String?
    
    init() {
        self.isMultiselect = true
        self.title = "What is your issue?"
        self.items = [SelectableItemViewModel(displayValue: "Item 1"), SelectableItemViewModel(displayValue: "Item 2"), SelectableItemViewModel(displayValue: "Item 3"), SelectableItemViewModel(displayValue: "Item 4")]
    }
}
