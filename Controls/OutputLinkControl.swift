//
//  OutputLinkControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputLinkControl: NSObject, ControlProtocol {
    
    class OutputLinkViewController: UIViewController, UITextViewDelegate {
        
        private(set) var textView = UITextView()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupTextView()
        }
        
        private func setupTextView() {
            textView.delegate = self
            textView.dataDetectorTypes = [.link]
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(textView)
            NSLayoutConstraint.activate([textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                         textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                         textView.topAnchor.constraint(equalTo: view.topAnchor),
                                         textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        }
        
        // MARK: UITextViewDelegate
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // TODO: display URL in a modal web view
            return true
        }
    }
    
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
        let outputLinkVC = OutputLinkViewController()
        self.viewController = outputLinkVC
        outputLinkVC.loadViewIfNeeded()
        outputLinkVC.textView.text = outputLinkModel.value.absoluteString
        
    }
}
