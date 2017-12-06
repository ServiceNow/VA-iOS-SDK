//
//  ChatterboxAdapter.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// MARK: Mimic Marc's Message model
struct BooleanControlMessage {}

protocol ChatterboxBooleanAdapter {
    init(message: BooleanControlMessage)
}

extension BooleanPickerControl {
    
    convenience init(message: BooleanPickerControl) {
        let booleanModel = BooleanControlViewModel(id: "1", title: "title")
        self.init(model: booleanModel)
    }
}
