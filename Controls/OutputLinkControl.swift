//
//  OutputLinkControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputLinkControl: NSObject, ControlProtocol {
    
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
        let label = outputLinkModel.label ?? outputLinkModel.value.absoluteString
        let attributedString = NSAttributedString(string: label, attributes: [NSAttributedStringKey.link : outputLinkModel.value])
        outputLinkVC.textView.attributedText = attributedString
        outputLinkVC.headerLabel.text = outputLinkModel.header
    }
}
