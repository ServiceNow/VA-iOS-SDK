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
    private let maxImageSize = CGSize(width: 250, height: 250)
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    
    private var imageConstraints = [NSLayoutConstraint]()
    private let outputImageView = UIImageView()
    
    var image: UIImage? {
        didSet {
            guard outputImageView.image != image else {
                return
            }
            
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
        imageConstraints.append(contentsOf: [outputImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                             outputImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                             outputImageView.topAnchor.constraint(equalTo: view.topAnchor),
                                             outputImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        imageHeightConstraint = outputImageView.heightAnchor.constraint(equalToConstant: 50)
        imageHeightConstraint?.isActive = true
        imageWidthConstraint = outputImageView.widthAnchor.constraint(equalToConstant: 100)
        imageWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate(imageConstraints)
        updateImageConstraints()
    }
    
    func prepareViewForImageWithSize(_ size: CGSize) {
        imageHeightConstraint?.constant = size.height
        imageWidthConstraint?.constant = size.width
    }
    
    private func updateImageConstraints() {
        // if image is in landscape - we will limit it horizontally. otherwise vertically.
        // set width/height proportion
        let imageSize = adjustedImageSize(for: image)
        imageHeightConstraint?.constant = imageSize.height
        imageWidthConstraint?.constant = imageSize.width
    }
    
    func adjustedImageSize(for image: UIImage?) -> CGSize {
        guard let image = image else {
            return CGSize(width: 100, height: 50)
        }
        
        if image.size.height > image.size.width {
            return adjustedImageHeight(for: image)
        } else {
            return adjustedImageWidth(for: image)
        }
    }
    
    private func adjustedImageHeight(for image: UIImage) -> CGSize {
        let imageSize: CGSize
        if image.size.height > maxImageSize.height {
            let height = maxImageSize.height
            let ratio = image.size.width / image.size.height
            let width = height * ratio
            imageSize = CGSize(width: width, height: height)
        } else {
            imageSize = image.size
        }
        
        return imageSize
    }
    
    private func adjustedImageWidth(for image: UIImage) -> CGSize {
        let imageSize: CGSize
        if image.size.width > maxImageSize.width {
            let ratio = image.size.height / image.size.width
            let height = maxImageSize.width * ratio
            imageSize = CGSize(width: maxImageSize.width, height: height)
        } else {
            imageSize = image.size
        }
        
        return imageSize
    }
}
