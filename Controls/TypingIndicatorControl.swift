//
//  TypingIndicatorControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// this control's model wont come from Chatterbox. It is predefined and only "direction" property might be changed
class TypingIndicatorViewModel: ControlViewModel {
    
    let label: String = "TypingIndicator"
    
    let isRequired: Bool = true
    
    let id: String = "typing_indicator"
    
    let type: ControlType = .typingIndicator
    
    var direction: ControlDirection = .inbound
}

class TypingIndicatorControl: ControlProtocol {
    
    class TypingIndicatorViewController: UIViewController {
        
        let typingIndicatorView = TypingIndicatorView()
        
        override func loadView() {
            view = typingIndicatorView
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            typingIndicatorView.startAnimating()
        }
    }
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let typingIndicatorModel = model as? TypingIndicatorViewModel else {
            fatalError("Tried to assign wrong model type")
        }
        
        self.model = typingIndicatorModel
        self.viewController = TypingIndicatorViewController()
    }
    
    convenience init() {
        self.init(model: TypingIndicatorViewModel())
    }
}
