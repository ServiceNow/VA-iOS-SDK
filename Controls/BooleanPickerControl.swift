//
//  BooleanPickerControl.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

class BooleanPickerControl: PickerControlProtocol {
    
    var style: PickerControlStyle = .inline
    
    var model: ControlViewModel
    
    weak var delegate: ControlDelegate?
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    required init(model: ControlViewModel) {
        assert(model.type == .boolean, "Model must be boolean type")
        self.model = model
    }
    
    // MARK: - PickerTableDelegate
    
    func pickerTable(_ pickerTable: PickerTableViewController, didSelectItem item: SelectableItemViewModel, forPickerModel pickerModel: PickerControlViewModel) {
        // FIXME: Add something in here
    }
}
