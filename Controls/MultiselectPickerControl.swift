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
    
    lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        self.model = model
        style = .inline
    }
    
    func submit() {
        
    }
    
    // MARK: - PickerTableDelegate
    
    func pickerTable(_ pickerTable: PickerTableViewController, didSelectItem item: SelectableItemViewModel, forPickerModel pickerModel: PickerControlViewModel) {
        // FIXME: Add something in here
    }
}
