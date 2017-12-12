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
    
    init(id: String, title: String, required: Bool) {
        let items = [SelectableItemViewModel(title: "Yes"), SelectableItemViewModel(title: "No")]
        super.init(id: id, title: title, required: required, items: items)
    }
}
