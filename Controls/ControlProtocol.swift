//
//  ControlProtocol.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

protocol ControlDelegate: class {
    
    func controlDidSubmitData(_ control: ControlProtocol)
}

protocol ControlProtocol: class {
    
    init(model: ControlViewModel)
    
    // representation of ui control state
    var model: ControlViewModel { get set }
    
    // UIViewController of ui control
    var viewController: UIViewController { get }
    
    weak var delegate: ControlDelegate? { get set }
    
    func submit()
}

enum PickerControlStyle: Int {
    
    // can be embedded anywhere in parent view
    case inline
    
    // is presented at the bottom of the screen
    case bottom
    
    // classic actionSheet
    case actionSheet
}

protocol PickerControlProtocol: ControlProtocol {
    
    var style: PickerControlStyle { get set }
}
