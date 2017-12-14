//
//  ControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

enum ControlType {
    
    case multiSelect
    
    case text
    
    case boolean
    
    case singleSelect
    
    case unknown
}

protocol ValueRepresentable {
    
    associatedtype ResultType
    
    var resultValue: ResultType? { get }
}

// base model for all ui control models
protocol ControlViewModel {
    
    // label of the control
    var label: String { get }
    
    // indicates whether uicontrol is required or not (i.e if input control has it set to false, "Skip" button is presented)
    var isRequired: Bool { get }
    
    var id: String { get }
    
    var type: ControlType { get }
}
