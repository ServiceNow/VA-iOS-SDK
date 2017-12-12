//
//  TextControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class TextControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        self.model = model
        self.viewController = UIViewController()
        setupTextView()
    }
    
    private func setupTextView() {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.isScrollEnabled = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.text = model.title
        textView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(textView)
        NSLayoutConstraint.activate([textView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
                                     textView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
                                     textView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                                     textView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)])
    }
}
