//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class BooleanControlViewModel: PickerControlViewModel {
    
    var isMultiselect: Bool
    
    var isRequired: Bool?
    
    var items: [SelectableItemViewModel]?
    
    var title: String?
    
    init() {
        self.isMultiselect = false
        self.title = "Would you like to create incident?"
        self.items = [SelectableItemViewModel(displayValue: "Yes"), SelectableItemViewModel(displayValue: "No")]
    }
}
