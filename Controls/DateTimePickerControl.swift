//
//  DateTimePickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class DateTimePickerControl: ControlProtocol {
    
    var model: ControlViewModel
    var viewController: UIViewController
    
    private var dateTimeViewModel: DateTimePickerControlViewModel {
        return model as! DateTimePickerControlViewModel
    }
    
    private var dateTimeViewController: DateTimePickerViewController {
        return viewController as! DateTimePickerViewController
    }
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let dateTimeViewModel = model as? DateTimePickerControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = dateTimeViewModel
        
        let bundle = Bundle(for: DateTimePickerViewController.self)
        let dateTimeViewController = DateTimePickerViewController(nibName: "DateTimePickerViewController", bundle: bundle)
        dateTimeViewController.loadViewIfNeeded()
        dateTimeViewController.model = dateTimeViewModel
        self.viewController = dateTimeViewController
        
        dateTimeViewController.doneButton.addTarget(self, action: #selector(selectedDoneButton(_:)), for: .touchUpInside)
    }
    
    @objc func selectedDoneButton(_ sender: UIButton) {
        delegate?.control(self, didFinishWithModel: model)
    }
}
