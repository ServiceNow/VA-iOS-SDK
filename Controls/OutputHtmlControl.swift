//
//  OutputHtmlControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputHtmlControl: ControlProtocol, FullSizeScrollViewContainerViewDelegate {
    
    var model: ControlViewModel
    
    let viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
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
        self.outputHtmlViewController.fullSizeContainer.uiDelegate = self
    }
    
    // MARK: FullSizeScrollViewContainerViewDelegate
    
    func fullSizeContainerViewDidInvalidateIntrinsicContentSize(_ fullSizeContainerView: FullSizeScrollViewContainerView) {
        let shouldUpdateHeight = fullSizeContainerView.intrinsicContentSize.height > 0
        guard shouldUpdateHeight, outputHtmlModel.size == nil else { return }
        outputHtmlModel.size = fullSizeContainerView.intrinsicContentSize
        delegate?.controlDidFinishLoading(self)
    }
}
