//
//  TextControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class TextControlViewModel: ControlViewModel {
    
    let label: String?
    
    let isRequired: Bool = true
    
    let id: String
    
    let type: ControlType = .text
    
    let value: String
    
    let messageDate: Date?
    
    init(id: String, label: String? = nil, value: String, messageDate: Date?) {
        self.label = label
        self.value = value
        self.id = id
        self.messageDate = messageDate
    }
}
