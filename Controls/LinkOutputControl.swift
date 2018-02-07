//
//  LinkOutputControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class LinkOutputControl: ControlProtocol {
    var model: ControlViewModel
    
    let viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let linkOutputModel = model as? OutputLinkControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = linkOutputModel
        self.viewController = UIViewController()
    }
}
