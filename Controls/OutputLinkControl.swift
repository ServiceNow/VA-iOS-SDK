//
//  OutputLinkControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputLinkControl: NSObject, ControlProtocol, UITextViewDelegate {
    var model: ControlViewModel
    
    let viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    private var outputLinkModel: OutputLinkControlViewModel {
        return model as! OutputLinkControlViewModel
    }
    
    required init(model: ControlViewModel) {
        guard let outputLinkModel = model as? OutputLinkControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = outputLinkModel
        self.viewController = UIViewController()
        setupTextView()
    }
    
    private func setupTextView() {
        let textView = UITextView()
        textView.delegate = self
        textView.dataDetectorTypes = [.link]
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.text = outputLinkModel.value.absoluteString
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(textView)
        NSLayoutConstraint.activate([textView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
                                     textView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
                                     textView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
                                     textView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)])
    }
    
    // MARK: UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // TODO: display URL in a modal web view
        return true
    }
}
