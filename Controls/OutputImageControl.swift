//
//  OutputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import AlamofireImage

protocol OutputImageControlDelegate: ControlDelegate {
    func controlDidFinishImageDownload(_ control: OutputImageControl)
}

class OutputImageControl: ControlProtocol {
    
    var model: ControlViewModel {
        didSet {
            refreshDownload()
        }
    }
    
    var viewController: UIViewController
    
    private var imageViewController: OutputImageViewController {
        return viewController as! OutputImageViewController
    }
    
    weak var delegate: ControlDelegate?
    
    private var outputImageDelegate: OutputImageControlDelegate? {
        return delegate as? OutputImageControlDelegate
    }
    
    private func refreshDownload() {
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
            
            // FIXME: Handle error / no image case
            
            self?.imageViewController.image = response.value
            
            guard let strongSelf = self else { return }
            self?.outputImageDelegate?.controlDidFinishImageDownload(strongSelf)
        }
    }
    
    var imageDownloader: ImageDownloader? {
        didSet {
            refreshDownload()
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
