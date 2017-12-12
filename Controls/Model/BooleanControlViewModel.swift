//
//  BooleanControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class BooleanControlViewModel: SingleSelectControlViewModel {
    
    override var type: CBControlType {
        return .boolean
    }
    
    init(id: String, label: String, required: Bool) {
        let items = [SelectableItemViewModel(label: "Yes"), SelectableItemViewModel(label: "No")]
        super.init(id: id, label: label, required: required, items: items)
    }
    
    var value: Bool? {
        guard let selectedItem = selectedItem else {
            return nil
        }
        
        // is Yes selected?
        return selectedItem === items[0]
    }
}
