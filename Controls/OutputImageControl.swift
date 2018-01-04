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
public protocol ImageDownloader: AnyObject {
    
    func downloadImage(forURL url: URL, completion: @escaping (UIImage?, Error?) -> Void)
}

class OutputImageControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    weak var imageDownloader: ImageDownloader? {
        didSet {
            guard let imageModel = model as? OutputImageViewModel else {
                Logger.default.logError("wrong model type")
                return
            }
            
            imageDownloader?.downloadImage(forURL: imageModel.value, completion: { [weak self] (image, error) in
                if let error = error {
                    Logger.default.logError("Error loading image from URL \(error)")
                    return
                }
                
                (self?.viewController as? OutputImageViewController)?.image = image
            })
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
