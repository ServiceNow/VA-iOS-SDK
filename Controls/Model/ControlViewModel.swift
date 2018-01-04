//
//  ControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// interface indicating that object should provide some result as ResultType
protocol ValueRepresentable {
    
    associatedtype ResultType
    
    var resultValue: ResultType? { get }
    
    var displayValue: String? { get }
}

enum ControlDirection {

    // inbound - for control/messages initiated by the user
    case inbound
    
    // outbound - controls send by the agent
    case outbound
    
    // FIXME: temporary because CB layer sends us string instead of enum
    static func direction(forStringValue value: String) -> ControlDirection {
        if value == "inbound" {
            return .inbound
        }
        if value == "outbound" {
            return .outbound
        }
        
        fatalError("ooops not sure what this direction value means!")
    }
}

// base model for all ui control models
protocol ControlViewModel {
    
    var label: String { get }
    
    // indicates whether user input is required or not (i.e if isRequired = false, "Skip" button is presented)
    var isRequired: Bool { get }
    
    var id: String { get }
    
    var type: ControlType { get }
    
    var direction: ControlDirection { get }
}
