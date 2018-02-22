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
            // Reset activityIndicator
            imageViewController.showActivityIndicator(true)
            refreshDownload()
        }
    }
    
    func prepareForReuse() {
        imageViewController.image = nil
        imageViewController.showActivityIndicator(false)
        imageViewController.outputImageView.af_cancelImageRequest()
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
        
        imageViewController.outputImageView.af_setImage(withURL: imageModel.value) { [weak self] (response) in
            
            guard let strongSelf = self else { return }
            strongSelf.imageViewController.showActivityIndicator(false)
            
            // FIXME: Handle error / no image case
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
