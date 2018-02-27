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
    private(set) var imageSize: CGSize?
    
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
        imageSize = size
        imageHeightConstraint?.constant = size.height
        imageWidthConstraint?.constant = size.width
        
        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }
    
    private func updateImageConstraints() {
        guard let image = image else {
            return
        }
        
        // if image is in landscape - we will limit it horizontally. otherwise vertically.
        // set width/height proportion
        if image.size.height > image.size.width {
            adjustImageHeightIfNeeded()
        } else {
            adjustImageWidthIfNeeded()
        }
        
        view.layoutIfNeeded()
    }
    
    private func adjustImageHeightIfNeeded() {
        guard let image = image, image.size.height > maxImageSize.height else {
            return
        }
        
        let height = maxImageSize.height
        let ratio = image.size.width / image.size.height
        let width = height * ratio
        imageHeightConstraint?.constant = height
        imageWidthConstraint?.constant = width
        imageSize = CGSize(width: width, height: height)
    }
    
    private func adjustImageWidthIfNeeded() {
        guard let image = image, image.size.width > maxImageSize.width else {
            return
        }
        
        let ratio = image.size.height / image.size.width
        let height = maxImageSize.width * ratio
        imageHeightConstraint?.constant = height
        imageWidthConstraint?.constant = maxImageSize.width
        imageSize = CGSize(width: maxImageSize.width, height: height)
    }
}
