//
//  ControlProtocol.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

protocol ControlDelegate: class {
    
}

protocol ControlProtocol: class {
    
    // representation of ui control state
    var model: ControlViewModel { get set }
    
    // UIViewController of ui control
    var viewController: UIViewController { get }
    
    weak var delegate: ControlDelegate? { get set }
    
    func submit()
}

enum PickerControlStyle: Int {
    
    case inline
    
    case actionSheet
}

protocol PickerControlProtocol: ControlProtocol {
    
    var style: PickerControlStyle { get set }
}
