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
    
    required init(model: ControlViewModel) {
        style = .inline
        let multiViewController = PickerTableViewController(model: model as! MultiselectControlViewModel)
        viewController = multiViewController
        self.model = model
    }
    
    func submit() {
        
    }
    
}
