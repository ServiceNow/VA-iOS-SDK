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
    var title: String? { get set }
    
    // indicates whether uicontrol is required or not (i.e if input control has it set to false, "Skip" button is presented)
    var isRequired: Bool? { get set }
}
