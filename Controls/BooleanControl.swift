//
//  BooleanPickerControl.swift
//  Controls
//
//  Created by Michael Borowiec on 11/8/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

class BooleanControl: PickerControlProtocol {
    
    var visibleItemCount: Int = PickerConstants.visibleItemCount
    
    var style: PickerControlStyle = .inline
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    weak var delegate: ControlDelegate?
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    required init(model: ControlViewModel) {
        self.model = model
    }
    
    // MARK: - PickerTableDelegate
    
    func pickerViewController(_ viewController: PickerViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {

    }
}
