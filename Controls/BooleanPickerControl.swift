//
//  BooleanPickerControl.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class BooleanPickerControl: ControlProtocol {
    
    var model: ControlViewModel?
    
    public var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    public init() {
        model = BooleanControlViewModel()
        
        let vc = PickerViewController()
        vc.model = model as? PickerControlViewModel
        viewController = vc
    }
    
    func submit() {
        
    }
}
