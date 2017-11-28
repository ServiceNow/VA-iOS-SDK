//
//  MultiselectPickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MultiselectPickerControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    public init() {
        model = MultiselectControlViewModel()
        
        let multiViewController = PickerTableViewController()
        multiViewController.model = model as? PickerControlViewModel
        viewController = multiViewController
    }
    
    func submit() {
        
    }
    
}
