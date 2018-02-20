//
//  ControlProtocol.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/14/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

enum ControlType {
    
    case multiSelect
    
    case text
    
    case outputImage
    
    case inputImage
    
    case outputLink
    
    case outputHtml
    
    case dateTime
    
    case time
    
    case date
    
    case boolean
    
    case singleSelect
    
    case typingIndicator
    
    case button
        
    func description() -> String {
        switch self {
        case .multiSelect:
            return "Multiselect"
        case .text:
            return "Text"
        case .outputImage:
            return "Image Output"
        case .inputImage:
            return "Image Input"
        case .outputLink:
            return "Link Output"
        case .outputHtml:
            return "Output HTML"
        case .dateTime:
            return "Date Time Picker"
        case .time:
            return "Time Picker"
        case .date:
            return "Date Picker"
        case .boolean:
            return "Boolean"
        case .singleSelect:
            return "Single Select"
        case .typingIndicator:
            return "Typing Indicator"
        case .button:
            return "Button"
        }
    }
}

// MARK: ControlDelegate

protocol ControlDelegate: AnyObject {
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel)
}

// MARK: Control Protocol

protocol ControlProtocol: AnyObject {
    
    init(model: ControlViewModel)
    
    // representation of ui control state
    var model: ControlViewModel { get set }
    
    // UIViewController of ui control
    var viewController: UIViewController { get }
    
    weak var delegate: ControlDelegate? { get set }
    
    func removeFromParent()
    
    // If provided - control will be limited to that size
    var maxContentSize: CGSize? { get }
}

// Code for self-removable control, just like UIView or UIViewController

extension ControlProtocol {
    
    var maxContentSize: CGSize? {
        return nil
    }
    
    func removeFromParent() {
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
}
