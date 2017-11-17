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
        self.model = BooleanControlViewModel()
    }
    
    var model: ControlViewModel?
    
    public var viewController: UIViewController?
    
    weak var delegate: ControlDelegate?
    
    func submit() {
        
    }
}
