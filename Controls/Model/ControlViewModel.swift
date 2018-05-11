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
    
    var resultValue: ResultType { get }
    
    var displayValue: String? { get }
}

// base model for all ui control models
protocol ControlViewModel {
    
    var label: String? { get }
    
    // indicates whether user input is required or not (i.e if isRequired = false, "Skip" button is presented)
    var isRequired: Bool { get }
    
    var id: String { get }
    
    var type: ControlType { get }
    
    var messageDate: Date? { get }
}

protocol Resizable {
    
    var size: CGSize? { get set }
}
