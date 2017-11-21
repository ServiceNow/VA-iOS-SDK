//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class BooleanControlViewModel: PickerControlViewModel {
    
    var isRequired: Bool?
    
    var items: [SelectableItemViewModel]?
    
    var title: String?
    
    init() {
        self.items = [SelectableItemViewModel(displayValue: "Yes"), SelectableItemViewModel(displayValue: "No")]
    }
}
