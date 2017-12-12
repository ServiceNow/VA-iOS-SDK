//
//  ControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// base model for all ui control models
protocol ControlViewModel {
    
    // label of the control
    var label: String { get }
    
//    var value: AnyObject? { get set }
    
    // indicates whether uicontrol is required or not (i.e if input control has it set to false, "Skip" button is presented)
    var isRequired: Bool { get }
    
    var id: String { get }
    
    var type: CBControlType { get }
}

class TextViewModel: ControlViewModel {
    
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
