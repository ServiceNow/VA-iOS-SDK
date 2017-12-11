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
    
    let isMultiSelect: Bool
    
    let items: [SelectableItemViewModel]
    
    let type: CBControlType = .boolean
    
    required convenience init(id: String, title: String, required: Bool) {
        let items = [BooleanControlOption.yes.selectableItemModel(), BooleanControlOption.no.selectableItemModel()]
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
