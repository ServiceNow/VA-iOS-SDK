//
//  OutputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class OutputImageControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let imageModel = model as? OutputImageViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = imageModel
        
        let bundle = Bundle(for: OutputImageViewController.self)
        let imageController = OutputImageViewController()
        let image = UIImage(named: "mark.png", in: bundle, compatibleWith: nil)
        imageController.setImage(image!)
        self.viewController = imageController
    }
}
