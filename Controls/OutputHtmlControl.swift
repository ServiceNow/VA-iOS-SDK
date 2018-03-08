//
//  OutputHtmlControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputHtmlControl: ControlProtocol, FullSizeScrollViewContainerViewDelegate {
    
    var model: ControlViewModel
    
    private var outputHtmlViewController: ControlWebViewController {
        return viewController as! ControlWebViewController
    }
    
    let viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel, resourceProvider: ControlWebResourceProvider) {
        guard let htmlModel = model as? OutputHtmlControlViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = htmlModel
        self.viewController = ControlWebViewController(htmlString: htmlModel.value, resourceProvider: resourceProvider)
        self.outputHtmlViewController.fullSizeContainer.uiDelegate = self
    }
    
    // MARK: FullSizeScrollViewContainerViewDelegate
    
    func fullSizeContainerViewDidInvalidateIntrinsicContentSize(_ fullSizeContainerView: FullSizeScrollViewContainerView) {
        delegate?.controlDidFinishLoading(self)
    }
}
