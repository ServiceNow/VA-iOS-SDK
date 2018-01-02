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
    
    func downloadImage(forURLRequest request: URLRequest, completion: (UIImage?, Error?) -> Void)
}

class OutputImageControl: ControlProtocol {
    
    var model: ControlViewModel
    
    var viewController: UIViewController
    
    weak var delegate: ControlDelegate?
    
    private var imageURLRequest: URLRequest?
    
    weak var imageDownloader: ImageDownloader? {
        didSet {
            guard let urlRequest = imageURLRequest else {
                fatalError("Image url request doesn't exist")
            }
            
            imageDownloader?.downloadImage(forURLRequest: urlRequest, completion: { [weak self] (image, error) in
                
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
        self.imageURLRequest = URLRequest(url: imageModel.value)
        self.viewController = OutputImageViewController()
    }
}
