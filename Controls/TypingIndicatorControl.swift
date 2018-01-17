//
//  TypingIndicatorControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// this control's model wont come from Chatterbox. It is predefined and only "direction" property might be changed
class TypingIndicatorViewModel: ControlViewModel {
    
    var label: String?
    
    let isRequired: Bool = true
    
    let id: String = "typing_indicator"
    
    let type: ControlType = .typingIndicator
}

class TypingIndicatorControl: ControlProtocol {
    
    var model: ControlViewModel {
        didSet {
            // restart animations
            typingIndicatorView.stopAnimating()
            typingIndicatorView.startAnimating()
        }
    }
    
    let typingIndicatorView = TypingIndicatorView()
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let typingIndicatorModel = model as? TypingIndicatorViewModel else {
            fatalError("Tried to assign wrong model type")
        }
        
        self.model = typingIndicatorModel
        self.viewController = UIViewController()
        setupTypingIndicator()
    }
    
    convenience init() {
        self.init(model: TypingIndicatorViewModel())
    }
    
    private func setupTypingIndicator() {
        typingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(typingIndicatorView)
        NSLayoutConstraint.activate([typingIndicatorView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 10),
                                     typingIndicatorView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -10),
                                     typingIndicatorView.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: 10),
                                     typingIndicatorView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor, constant: -10)])
        typingIndicatorView.setContentHuggingPriority(.required, for: .horizontal)
        typingIndicatorView.setContentHuggingPriority(.required, for: .vertical)
        
        typingIndicatorView.startAnimating()
    }
}
