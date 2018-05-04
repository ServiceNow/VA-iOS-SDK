//
//  OutputLinkControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputLinkControl: NSObject, ControlProtocol {
    
    var model: ControlViewModel {
        didSet {
            updateOutputLinkViewController()
        }
    }
    
    let viewController: UIViewController
    
    private var outputLinkViewController: OutputLinkViewController {
        return viewController as! OutputLinkViewController
    }
    
    // swiftlint:disable:next weak_delegate
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
        super.init()
        updateOutputLinkViewController()
    }
    
    private func updateOutputLinkViewController() {
        let label = outputLinkModel.label ?? outputLinkModel.value.absoluteString
        let attributedString = NSAttributedString(string: label, attributes: [NSAttributedStringKey.link: outputLinkModel.value.absoluteString,
                                                                              NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body)])
        outputLinkViewController.textView.attributedText = attributedString
        
        outputLinkViewController.headerLabel.text = outputLinkModel.header ?? outputLinkModel.value.host
    }
    
    // MARK: Theme
    
    func applyTheme(_ theme: ControlTheme?) {
        outputLinkViewController.headerLabel.textColor = theme?.fontColor
        outputLinkViewController.headerContainerView.backgroundColor = theme?.backgroundColor
        outputLinkViewController.textView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: theme?.linkColor ?? .blue]
        outputLinkViewController.textView.backgroundColor = theme?.buttonBackgroundColor
        outputLinkViewController.view.backgroundColor = theme?.buttonBackgroundColor
    }
}
