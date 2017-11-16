//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

struct BooleanControlViewModel: PickerControlViewModel {
    
    var displayValues: [String?]?
    
    var isRequired: Bool?
    
    var items: [SelectableItemViewModel]?
    
    var selectedItems: [SelectableItemViewModel]?
    
    var title: String?
    
    init() {
        self.items = [SelectableItemViewModel(displayValue: "YES"), SelectableItemViewModel(displayValue: "NO")]
    }
}
