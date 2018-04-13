//
//  OutputLinkViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 4/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputLinkViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerContainerView: UIView!
    
    let resourceProvider: ControlWebResourceProvider
    
    init(resourceProvider: ControlWebResourceProvider) {
        self.resourceProvider = resourceProvider
        let bundle = Bundle(for: OutputLinkViewController.self)
        super.init(nibName: "OutputLinkViewController", bundle: bundle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
    }
    
    // MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        return false
    }
}
