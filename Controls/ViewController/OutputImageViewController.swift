//
//  OutputImageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class OutputImageViewController: UIViewController {
    
    // Putting these constraints on image for now
    let maxImageSize = CGSize(width: 250, height: 250)
    var imageViewWidthToHeightConstraint: NSLayoutConstraint?
    var imageViewSideConstraint: NSLayoutConstraint?
    
    let outputImageView = UIImageView()
    
    var image: UIImage? {
        didSet {
            outputImageView.image = image            
            updateImageConstraints()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOutputImageView()
    }
    
    private func setupOutputImageView() {
        outputImageView.contentMode = .scaleAspectFill
        outputImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outputImageView)
        NSLayoutConstraint.activate([outputImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     outputImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     outputImageView.topAnchor.constraint(equalTo: view.topAnchor),
                                     outputImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        updateImageConstraints()
    }
    
    private func updateImageConstraints() {
        imageViewWidthToHeightConstraint?.isActive = false
        imageViewSideConstraint?.isActive = false

        guard let image = image, image.size.height > maxImageSize.height || image.size.width > maxImageSize.width else {
            return
        }
        
        // if image is in landscape - we will limit it horizontally. otherwise vertically.
        // set width/height proportion
        let ratio: CGFloat
        if image.size.height > image.size.width {
            imageViewSideConstraint = outputImageView.heightAnchor.constraint(lessThanOrEqualToConstant: maxImageSize.height)
            ratio = image.size.width / image.size.height
            imageViewWidthToHeightConstraint = outputImageView.widthAnchor.constraint(equalTo: outputImageView.heightAnchor, multiplier: ratio)
        } else {
            imageViewSideConstraint = outputImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxImageSize.width)
            ratio = image.size.height / image.size.width
            imageViewWidthToHeightConstraint = outputImageView.heightAnchor.constraint(equalTo: outputImageView.widthAnchor, multiplier: ratio)
        }
    
        imageViewWidthToHeightConstraint?.isActive = true
        imageViewSideConstraint?.isActive = true
    }
}
