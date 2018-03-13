//
//  OutputHtmlControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputHtmlControl: ControlProtocol {
    
    var model: ControlViewModel {
        didSet {
            // load new html
            outputHtmlViewController.load(outputHtmlModel.value)
            
            guard let oldHtmlModel = oldValue as? OutputHtmlControlViewModel else { return }
            guard let newSize = outputHtmlModel.size, let oldSize = oldHtmlModel.size, !newSize.equalTo(oldSize) else { return }
            
            // if sizes are different, we have to update cell height. That's the way to do it.
            delegate?.controlDidFinishLoading(self)
        }
    }
    
    var isReusable: Bool {
        return !outputHtmlViewController.hasNavigated
    }
    
    var preferredContentSize: CGSize? {
        return outputHtmlModel.size
    }
    
    weak var delegate: ControlDelegate?
    
    let viewController: UIViewController
    
    private var outputHtmlViewController: ControlWebViewController {
        return viewController as! ControlWebViewController
    }
    
    private var outputHtmlModel: OutputHtmlControlViewModel {
        return model as! OutputHtmlControlViewModel
    }
    
    required init(model: ControlViewModel, resourceProvider: ControlWebResourceProvider) {
        guard let htmlModel = model as? OutputHtmlControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = htmlModel
        self.viewController = ControlWebViewController(htmlString: htmlModel.value, resourceProvider: resourceProvider)
    }
}
