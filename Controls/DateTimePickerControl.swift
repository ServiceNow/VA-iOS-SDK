//
//  DateTimePickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class DateTimePickerControl: ControlProtocol {
    
    private var dateTimeViewModel: DateTimePickerControlViewModel {
        return model as! DateTimePickerControlViewModel
    }
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let dateTimeViewModel = model as? DateTimePickerControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = dateTimeViewModel
        self.viewController = UIViewController()
    }
}
