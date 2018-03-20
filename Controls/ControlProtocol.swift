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
    
    case carousel
    
    case typingIndicator
    
    case button

    //swiftlint:disable:next cyclomatic_complexity
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
        case .carousel:
            return "Carousel"
        case .typingIndicator:
            return "Typing Indicator"
        case .button:
            return "Button"
        }
    }
}

// MARK: - ControlDelegate

protocol ControlDelegate: AnyObject {
    
    func control(_ control: ControlProtocol, didFinishWithModel model: ControlViewModel)
    
    func controlDidFinishLoading(_ control: ControlProtocol)
}

// MARK: - Control Protocol

protocol ControlProtocol: AnyObject, ControlThemeable {
    
    // representation of ui control state
    var model: ControlViewModel { get set }
    
    // UIViewController of ui control
    var viewController: UIViewController { get }
    
    weak var delegate: ControlDelegate? { get set }
    
    // If provided - control will be limited to that size
    var preferredContentSize: CGSize? { get }
    
    var isReusable: Bool { get }
    
    // removes viewController and view of the control from the hierarchy
    func removeFromParent()
    
    // called immediately after control was initialized and is ready to use
    func controlDidLoad()
    
    // cleans up all necessary vars so they are ready for reuse. Default implementation does nothing.
    func prepareForReuse()
}

// Code for self-removable control, just like UIView or UIViewController

extension ControlProtocol {
    
    func controlDidLoad() {
    }
    
    func prepareForReuse() {
    }
    
    var preferredContentSize: CGSize? {
        return nil
    }
    
    var isReusable: Bool {
        return true
    }
    
    func removeFromParent() {
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
}
