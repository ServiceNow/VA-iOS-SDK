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
        
        let resourceProvider: ControlWebResourceProvider
        
        init(resourceProvider: ControlWebResourceProvider) {
            self.resourceProvider = resourceProvider
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
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
            let webViewController = ControlWebViewController(url: URL, resourceProvider: resourceProvider)
            let localizedDoneString = NSLocalizedString("Done", comment: "Done button")
            let doneButton = UIBarButtonItem(title: localizedDoneString, style: .done, target: webViewController, action: #selector(finishModalPresentation(_:)))
            webViewController.navigationItem.leftBarButtonItem = doneButton
            let navigationController = UINavigationController(rootViewController: webViewController)
            navigationController.modalPresentationStyle = .overFullScreen
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
    
    init(model: ControlViewModel, resourceProvider: ControlWebResourceProvider) {
        guard let outputLinkModel = model as? OutputLinkControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = outputLinkModel
        let outputLinkVC = OutputLinkViewController(resourceProvider: resourceProvider)
        self.viewController = outputLinkVC
        outputLinkVC.loadViewIfNeeded()
        outputLinkVC.textView.text = outputLinkModel.value.absoluteString
        
    }
}
