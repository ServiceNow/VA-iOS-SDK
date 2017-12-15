//
//  ControlProtocol.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// MARK: - ControlState

// ControlState describes what is the state of the control.
// State might change when user selects item from the list in picker, or when input control transforms into output control.
// Typically control's state will change on control's submit/select action
enum ControlState {
    
    // initial state of the UI Control (before user applies response)
    case regular
    
    case submitted
}

// MARK: ControlDelegate

protocol ControlDelegate: AnyObject {
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel)
}

// MARK: Control Protocol

protocol ControlProtocol: AnyObject {
    
    init(model: ControlViewModel)
    
    // current state of the control
    var state: ControlState { get set }
    
    // representation of ui control state
    var model: ControlViewModel { get set }
    
    // UIViewController of ui control
    var viewController: UIViewController { get }
    
    weak var delegate: ControlDelegate? { get set }
}

// adds adaptivity to a different control' state
protocol ControlStateAdaptable where Self: UIViewController {
    
    // depending on the state, UIControl might provide additional view that represents response that user provided.
//    var responseView: UIView? { get }
    
    func updateControlState(_ state: ControlState)
}
