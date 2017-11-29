//
//  MultiselectPickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MultiselectPickerControl: PickerControlProtocol {
    
    var model: ControlViewModel
    
    var style: PickerControlStyle
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    public init() {
        style = .inline
        let model = MultiselectControlViewModel()
        let multiViewController = PickerTableViewController(model: model)
        viewController = multiViewController
        self.model = model
    }
    
    func submit() {
        
    }
    
}
