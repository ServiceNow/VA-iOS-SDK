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
    
    case boolean
    
    case singleSelect
    
    case typingIndicator
    
    case multiPart
    
    func description() -> String {
        switch self {
        case .multiSelect:
            return "Multiselect"
        case .text:
            return "Text"
        case .outputImage:
            return "Image Output"
        case .boolean:
            return "Boolean"
        case .singleSelect:
            return "Single Select"
        case .typingIndicator:
            return "Typing Indicator"
        case .multiPart:
            return "MultiPart"
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
}
