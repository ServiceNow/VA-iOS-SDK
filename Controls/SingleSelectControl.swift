//
//  SingleSelectControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class SingleSelectControl: PickerControlProtocol {
    
    var visibleItemCount: Int = PickerConstants.visibleItemCount
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    var style: PickerControlStyle
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        self.model = model
        self.style = .list
    }
    
    func pickerViewController(_ viewController: UIViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {

    }
}
