//
//  OutputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// FIXME: this protocol will have to be improved

// whoever uses OutputImageControl is responsible for conforming and implementing ImageDownloader protocol
// ImageDownloader was added to make OutputImageControl independent of networking client

import AlamofireImage

class OutputImageControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    private var imageViewController: OutputImageViewController {
        return viewController as! OutputImageViewController
    }
    
    weak var delegate: ControlDelegate?
    
    var imageDownloader: ImageDownloader? {
        didSet {
            guard let imageModel = model as? OutputImageViewModel else {
                Logger.default.logError("wrong model type")
                return
            }
            
            let urlRequest = URLRequest(url: imageModel.value)
            
            imageDownloader?.download(urlRequest) { [weak self] (response) in
                guard let currentModel = self?.model as? OutputImageViewModel,
                    imageModel.value == currentModel.value else {
                        return
                }
                
                self?.imageViewController.image = response.value
            }
        }
    }

    required init(model: ControlViewModel) {
        guard let imageModel = model as? OutputImageViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = imageModel
        self.viewController = OutputImageViewController()
    }
    
}
