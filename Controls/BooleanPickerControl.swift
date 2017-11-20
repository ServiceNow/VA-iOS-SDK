//
//  BooleanPickerControl.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class BooleanPickerControl: ControlProtocol {
    
    public init() {
        model = BooleanControlViewModel()
    }
    
    var model: ControlViewModel?
    
    public lazy var viewController: UIViewController? = {
        let vc = PickerViewController()
        vc.model = model as? PickerControlViewModel
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    func submit() {
        
    }
}
