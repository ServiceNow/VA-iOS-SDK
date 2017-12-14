//
//  TextControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class TextViewModel: ControlViewModel {
    
    let label: String
    
    let isRequired: Bool = true
    
    let id: String
    
    let type: ControlType = .text
    
    let value: String
    
    init(id: String = "text_control", label: String, value: String) {
        self.label = label
        self.value = value
        self.id = id
    }
}
