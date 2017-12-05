//
//  ControlProtocol.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

protocol ControlDelegate: AnyObject {
    
    func controlDidSubmitData(_ control: ControlProtocol)
}

protocol ControlProtocol: AnyObject {
    
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

// MARK: - PickerControlProtocol

protocol PickerControlProtocol: ControlProtocol {
    
    var style: PickerControlStyle { get set }
    
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel) -> UIViewController
}

extension PickerControlProtocol {
    
    // default implementation of protocol method. returns viewController based on provided style of the picker
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel) -> UIViewController {
        guard let model = model as? PickerControlViewModel else {
            fatalError("Wrong model class")
        }
        
        switch style {
        case .inline:
            let tableViewController = PickerTableViewController(model: model)
            return tableViewController
            
        // FIXME: need to add proper stuff in here
        case .bottom, .actionSheet:
            let actionSheet = UIAlertController()
            return actionSheet
        }
    }
}
