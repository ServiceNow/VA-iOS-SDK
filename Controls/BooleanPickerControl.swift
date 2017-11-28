//
//  BooleanPickerControl.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class BooleanPickerControl: PickerControlProtocol {
    
    var style: PickerControlStyle
    
    var model: ControlViewModel
    
    weak var delegate: ControlDelegate?
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    public init() {
        model = BooleanControlViewModel()
        style = .inline
    }
    
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel?) -> UIViewController {
        switch style {
        case .inline:
            let tableViewController = PickerTableViewController()
            tableViewController.model = model as? PickerControlViewModel
            return tableViewController
        case .actionSheet:
            let actionSheet = UIAlertController()
            return actionSheet
        }
    }
    
    func submit() {
        
    }
}
