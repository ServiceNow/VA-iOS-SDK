//
//  OutputHtmlControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class OutputHtmlControl: ControlProtocol, ControlWebViewControllerDelegate {
    
    var model: ControlViewModel
    
    var isReusable: Bool {
        return false
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
        self.outputHtmlViewController.uiDelegate = self
    }
    
    // MARK: FullSizeScrollViewContainerViewDelegate
    
    func webViewController(_ webViewController: ControlWebViewController, didFinishLoadingWebViewWithSize size: CGSize) {
        print("Size: \(size)")
        outputHtmlModel.size = size
        delegate?.controlDidFinishLoading(self)
    }
}
