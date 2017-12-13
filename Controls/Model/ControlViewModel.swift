//
//  ControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

enum ControlValue {
    case bool(Bool)
    case string(String)
    case null
    
    func getBool() -> Bool? {
        switch self {
        case .bool(let value):
            return value
        case .null: fallthrough
        case .string:
            return nil
        }
    }
    
    func getString() -> String? {
        switch self {
        case .null: fallthrough
        case .bool:
            return nil
        case .string(let value):
            return value
        }
    }
}

// base model for all ui control models
protocol ControlViewModel {
    
    // Might be String, Bool or Number depending on what Control is using it
    var value: ControlValue? { get }
    
    // label of the control
    var label: String { get }
    
    // indicates whether uicontrol is required or not (i.e if input control has it set to false, "Skip" button is presented)
    var isRequired: Bool { get }
    
    var id: String { get }
    
    var type: CBControlType { get }
}
