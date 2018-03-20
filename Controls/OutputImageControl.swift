//
//  OutputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import AlamofireImage

class OutputImageControl: ControlProtocol {
    
    weak var delegate: ControlDelegate?
    
    var viewController: UIViewController
    
    let imageDownloader: ImageDownloader
    
    private var imageViewController: OutputImageViewController {
        return viewController as! OutputImageViewController
    }
    
    private var imageModel: OutputImageViewModel {
        return model as! OutputImageViewModel
    }
    
    private var requestReceipt: RequestReceipt?
    
    var model: ControlViewModel {
        didSet {
            if let size = imageModel.size {
                imageViewController.prepareViewForImageWithSize(size)
            }
        }
    }
    
    required init(model: ControlViewModel, imageDownloader: ImageDownloader) {
        guard let imageModel = model as? OutputImageViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = imageModel
        self.imageDownloader = imageDownloader
        self.viewController = OutputImageViewController()
    }
    
    func controlDidLoad() {
        downloadImageIfNeeded()
    }
    
    private func downloadImageIfNeeded() {
        let imageModel = self.imageModel
        let urlRequest = URLRequest(url: imageModel.value)
        requestReceipt = imageDownloader.download(urlRequest) { [weak self] (response) in
            guard let currentModel = self?.model as? OutputImageViewModel,
                imageModel.value == currentModel.value else {
                    return
            }
            
            // FIXME: Handle error / no image case
            if response.error != nil {
                return
            }

            let image = response.value
            guard let strongSelf = self, strongSelf.imageViewController.image != image else { return }
            
            // If we already fetched image before we don't need to call beginUpdate/endUpdate on tableView
            // Which is called in didFinishImageDownload
            let needsLayoutUpdate = strongSelf.imageModel.size == nil
            strongSelf.imageViewController.image = image
            strongSelf.imageModel.size = strongSelf.imageViewController.imageSize
            
            if needsLayoutUpdate {
                strongSelf.delegate?.controlDidFinishLoading(strongSelf)
            }
        }
    }
    
    func prepareForReuse() {
        if let receipt = requestReceipt {
            imageDownloader.cancelRequest(with: receipt)
            requestReceipt = nil
        }
        
        delegate = nil
        imageViewController.image = nil
    }
}
