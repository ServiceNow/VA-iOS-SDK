//
//  MultiPartControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class MultiPartControlViewModel: ControlViewModel {
    var label: String?
    
    let isRequired = true
    
    let id: String
    
    let type: ControlType = .multiPart
    
    var value: Int
    
    init(id: String, label: String? = nil, value: Int) {
        self.id = id
        self.label = label
        self.value = value
    }
}

class MultiPartControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let multiPartModel = model as? MultiPartControlViewModel else {
            fatalError("Tried to assign wrong model type")
        }
        
        self.model = multiPartModel
        self.viewController = UIViewController()
    }
}
