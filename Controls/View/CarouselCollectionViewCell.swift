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
    private var imageDownloader: ImageDownloader?
    @IBOutlet private weak var imageView: UIImageView?
    
    func configure(withCarouselItem item: CarouselItem, imageDownloader: ImageDownloader) {
        if let attachmentURL = item.attachment {
            self.imageDownloader = imageDownloader
            let urlRequest = URLRequest(url: attachmentURL)
            requestReceipt = imageDownloader.download(urlRequest) { [weak self] (response) in
                
                // TODO: Handle error / no image case
                if response.error != nil {
                    return
                }
                self?.imageView?.image = response.value
            }
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
