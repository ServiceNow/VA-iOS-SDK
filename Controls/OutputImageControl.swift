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
    
    func prepareForReuse() {
        if let receipt = requestReceipt {
            imageDownloader?.cancelRequest(with: receipt)
            requestReceipt = nil
        }
        
        imageViewController.image = nil
        imageViewController.showActivityIndicator(false)
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
            
            guard let strongSelf = self else { return }
            strongSelf.imageViewController.showActivityIndicator(false)
            strongSelf.imageViewController.image = response.value
            strongSelf.outputImageDelegate?.controlDidFinishImageDownload(strongSelf)
        }
    }
    
    var imageDownloader: ImageDownloader? {
        didSet {
            imageViewController.outputImageView.af_imageDownloader = imageDownloader
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
