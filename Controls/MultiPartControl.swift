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
    
    let id = "multipart"
    
    let type: ControlType = .multiPart
}

class MultiPartControl: ControlProtocol {
    required init(model: ControlViewModel) {
        
    }
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    var delegate: ControlDelegate?
}
