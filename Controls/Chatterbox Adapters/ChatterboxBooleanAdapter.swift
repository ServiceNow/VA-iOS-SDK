//
//  ChatterboxAdapter.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

protocol ChatterboxBooleanAdapter {
    init(message: BooleanControlMessage)
}

extension BooleanPickerControl {
    
    convenience init(message: BooleanControlMessage) {
        let booleanModel = BooleanControlViewModel(id: "1", title: "title")
        self.init(model: booleanModel)
    }
}
