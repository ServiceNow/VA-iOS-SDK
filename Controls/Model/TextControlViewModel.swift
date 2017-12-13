//
//  TextControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class TextViewModel: ControlViewModel {
    
    var value: ControlValue?
    
    let label: String
    
    let isRequired: Bool
    
    let id: String
    
    let type: CBControlType = .text
    
    init(id: String = "text_control", label: String, required: Bool = true) {
        self.label = label
        self.isRequired = required
        self.id = id
    }
}
