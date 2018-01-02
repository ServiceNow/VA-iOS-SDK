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
    let outputImageView = UIImageView()
    var imageViewWidthToHeightConstraint: NSLayoutConstraint?
    var imageViewSideConstraint: NSLayoutConstraint?
    
    var image: UIImage? {
        didSet {
            updateImageConstraints()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outputImageView)
        NSLayoutConstraint.activate([outputImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     outputImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     outputImageView.topAnchor.constraint(equalTo: view.topAnchor),
                                     outputImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    
    private func updateImageConstraints() {
        imageViewWidthToHeightConstraint?.isActive = false
        imageViewSideConstraint?.isActive = false
        guard let image = image else {
            return
        }
        
        // if image is landscape - we will limit it horizontally. otherwise vertically.
        if image.size.height > image.size.width {
            imageViewSideConstraint = outputImageView.heightAnchor.constraint(lessThanOrEqualToConstant: maxImageSize.height)
        } else {
            imageViewSideConstraint = outputImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxImageSize.width)
        }
        
        // set width/height proportion
        let ratio = image.size.width / image.size.height
        imageViewWidthToHeightConstraint = outputImageView.heightAnchor.constraint(equalTo: outputImageView.widthAnchor, multiplier: ratio)
        imageViewWidthToHeightConstraint?.priority = .veryHigh
        imageViewWidthToHeightConstraint?.isActive = true
        imageViewSideConstraint?.isActive = true
        outputImageView.image = image
    }
}
