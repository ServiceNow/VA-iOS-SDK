//
//  ControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// base model for all ui control models
public protocol ControlViewModel {
    
    // title of the control
    var title: String { get }
    
    // indicates whether uicontrol is required or not (i.e if input control has it set to false, "Skip" button is presented)
    var isRequired: Bool { get }
    
    var id: String { get }
    
    var type: Control { get }
    
    init(id: String, title: String, required: Bool)
}

class TextViewModel: ControlViewModel {
    
    let title: String
    
    let isRequired: Bool
    
    let id: String
    
    var type: Control {
        return .text
    }
    
    required init(id: String = "text_control", title: String, required: Bool = true) {
        self.title = title
        self.isRequired = required
        self.id = id
    }
}
