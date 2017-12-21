//
//  OutputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class OutputImageViewModel: ControlViewModel {
    
    let label: String
    
    var isRequired: Bool = true
    
    let id: String
    
    let type: ControlType = .outputImage
    
    let direction: ControlDirection
    
    let value: String
    
    init(id: String = "image_output", label: String, value: String, direction: ControlDirection) {
        self.label = label
        self.value = value
        self.id = id
        self.direction = direction
    }
}

class OutputImageControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController = UIViewController()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let imageModel = model as? OutputImageViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = imageModel
    }
}
