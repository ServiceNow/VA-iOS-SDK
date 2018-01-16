//
//  TextControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class TextControl: ControlProtocol {
    
    // Private class to handle custom view controller for Text Control.
    class TextViewController: UIViewController {
        
        let textLabel = UILabel()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            textLabel.numberOfLines = 0
            textLabel.setContentHuggingPriority(.required, for: .horizontal)
            textLabel.setContentHuggingPriority(.required, for: .vertical)
            textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            textLabel.font = UIFont.preferredFont(forTextStyle: .body)
            
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(textLabel)
            NSLayoutConstraint.activate([textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                                         textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                                         textLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                                         textLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)])
        }
    }
    
    var model: ControlViewModel {
        didSet {
            guard let textViewController = viewController as? TextViewController,
                let textModel = model as? TextControlViewModel else {
                    return
            }
            
            textViewController.textLabel.text = textModel.value
            textViewController.view.layoutIfNeeded()
        }
    }
    
    let viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let textModel = model as? TextControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = textModel   
        let textViewController = TextViewController()
        textViewController.textLabel.text = textModel.value
        self.viewController = textViewController
    }
}
