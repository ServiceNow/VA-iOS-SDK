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
            textView.font = .preferredFont(forTextStyle: .body)
            textView.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(textView)
            NSLayoutConstraint.activate([textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                         textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                         textView.topAnchor.constraint(equalTo: view.topAnchor),
                                         textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        }
        
        // MARK: UITextViewDelegate
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            let webViewController = ControlWebViewController(request: URLRequest(url: URL))
            let localizedDoneString = NSLocalizedString("Done", comment: "Done button")
            let doneButton = UIBarButtonItem(title: localizedDoneString, style: .done, target: webViewController, action: #selector(finishModalPresentation(_:)))
            webViewController.navigationItem.leftBarButtonItem = doneButton
            let navigationController = UINavigationController(rootViewController: webViewController)
            present(navigationController, animated: true, completion: nil)
            return false
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
