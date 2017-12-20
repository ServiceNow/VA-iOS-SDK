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
    private class TextViewController: UIViewController {
        
        let textView = UITextView()
        
        override func loadView() {
            self.view = textView
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            textView.setContentHuggingPriority(.required, for: .horizontal)
            textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            textView.isScrollEnabled = false // to turn on autoresizing
            textView.isEditable = false
            textView.font = UIFont.preferredFont(forTextStyle: .body)
        }
    }
    
    var model: ControlViewModel
    
    let viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let textModel = model as? TextControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = textModel   
        let textViewController = TextViewController()
        textViewController.textView.text = textModel.value
        self.viewController = textViewController
    }
}