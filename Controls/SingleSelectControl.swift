//
//  SingleSelectControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class SingleSelectControl: PickerControlProtocol {
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    var style: PickerControlStyle
    
    var model: ControlViewModel
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        self.model = model
        self.style = .inline
    }
    
    func pickerTable(_ pickerTable: PickerTableViewController, didSelectItem item: SelectableItemViewModel, forPickerModel pickerModel: PickerControlViewModel) {
        // FIXME: Something add here
    }
}
