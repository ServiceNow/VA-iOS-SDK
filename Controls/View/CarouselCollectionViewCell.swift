//
//  CarouselCollectionViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/28/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import AlamofireImage

class CarouselCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "CarouselCollectionViewCellIdentifier"
    private var requestReceipt: RequestReceipt?
    private var resourceProvider: ControlWebResourceProvider?
    private var imageDownloader: ImageDownloader?
    @IBOutlet private weak var imageView: UIImageView?
    
    func configure(withCarouselItem item: CarouselItem, resourceProvider: ControlResourceProvider) {
        guard let attachmentURL = item.attachment else { return }
        
        imageDownloader = resourceProvider.imageDownloader
        
        let urlRequest = resourceProvider.authorizedImageRequest(with: attachmentURL)
        requestReceipt = imageDownloader?.download(urlRequest) { [weak self] (response) in
            
            guard response.error == nil else {
                // TODO: Handle error / no image case: placeholder?
                return
            }

            self?.imageView?.image = response.value
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if let request = requestReceipt {
            imageDownloader?.cancelRequest(with: request)
            requestReceipt = nil
        }
        
        imageView?.image = nil
    }
}
