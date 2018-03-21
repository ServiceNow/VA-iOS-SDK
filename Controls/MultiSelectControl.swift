//
//  MultiselectPickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MultiSelectControl: PickerControlProtocol {
    
    var visibleItemCount: Int = PickerConstants.visibleItemCount
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    var style: PickerControlStyle
    
    lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let multiSelectModel = model as? MultiSelectControlViewModel else {
            fatalError("Wrong model type")
        }

        self.model = multiSelectModel
        style = .list
    }
    
    // MARK: - PickerViewControllerDelegate
    
    func pickerViewController(_ viewController: UIViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {
        // FIXME: Add something in here
    }
}
