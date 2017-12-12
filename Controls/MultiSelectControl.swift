//
//  MultiselectPickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MultiSelectControl: PickerControlProtocol {
    
    var model: ControlViewModel
    
    var style: PickerControlStyle
    
    lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        assert(model.type == .multiSelect, "Model must be multiselect type")
        self.model = model
        style = .inline
    }
    
    // MARK: - PickerTableDelegate
    
    func pickerTable(_ pickerTable: PickerTableViewController, didSelectItem item: SelectableItemViewModel, forPickerModel pickerModel: PickerControlViewModel) {
        // FIXME: Add something in here
    }
}
