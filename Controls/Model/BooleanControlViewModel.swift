//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

enum BooleanControlOption: String {
    case yes = "Yes"
    case no = "No"
    
    func selectableItemModel() -> SelectableItemViewModel {
        return SelectableItemViewModel(title: self.rawValue)
    }
}

class BooleanControlViewModel: PickerControlViewModel {
    
    let id: String
    
    let title: String
    
    let isRequired: Bool
    
    var isMultiselect: Bool = false
    
    let items: [SelectableItemViewModel]?
    
    var type: Control {
        return .boolean
    }
    
    required init(id: String, title: String, required: Bool = true) {
        self.id = id
        self.title = title
        self.isRequired = required
        self.items = [BooleanControlOption.yes.selectableItemModel(), BooleanControlOption.no.selectableItemModel()]
    }
}
