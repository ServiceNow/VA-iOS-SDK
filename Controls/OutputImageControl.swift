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
    
    weak var delegate: ControlDelegate?
    
    var viewController: UIViewController
    
    private var imageViewController: OutputImageViewController {
        return viewController as! OutputImageViewController
    }
    
    private var outputImageDelegate: OutputImageControlDelegate? {
        return delegate as? OutputImageControlDelegate
    }
    
    private var imageModel: OutputImageViewModel {
        return model as! OutputImageViewModel
    }
    
    private var requestReceipt: RequestReceipt?
    
    var model: ControlViewModel {
        didSet {
            // Reset activityIndicator
            imageViewController.showActivityIndicator(true)
            refreshDownload()
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
    
    private func refreshDownload() {
        let urlRequest = URLRequest(url: imageModel.value)
        requestReceipt = imageDownloader?.download(urlRequest) { [weak self] (response) in
            // Very likely could remove that guard since we are cancelling request on reuse
            guard let currentModel = self?.model as? OutputImageViewModel,
                self?.imageModel.value == currentModel.value else {
                    return
            }
            
            // FIXME: Handle error / no image case
            if response.error != nil {
                return
            }
            
            let image = response.value
            guard let strongSelf = self, strongSelf.imageViewController.image != image else { return }
            strongSelf.imageViewController.showActivityIndicator(false)
            strongSelf.imageViewController.image = image
            strongSelf.outputImageDelegate?.controlDidFinishImageDownload(strongSelf)
        }
    }
    
    func prepareForReuse() {
        if let receipt = requestReceipt {
            imageDownloader?.cancelRequest(with: receipt)
            requestReceipt = nil
        }
        
        delegate = nil
        imageViewController.image = nil
        imageViewController.showActivityIndicator(false)
    }
}
