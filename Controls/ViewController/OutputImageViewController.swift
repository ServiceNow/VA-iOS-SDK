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
    private let imageSize = CGSize(width: 160, height: 160)
    private var imageWidthConstraint: NSLayoutConstraint?
    
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
                                             outputImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                             outputImageView.heightAnchor.constraint(equalToConstant: imageSize.height)])
        
        imageWidthConstraint = outputImageView.widthAnchor.constraint(equalToConstant: imageSize.width)
        imageWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate(imageConstraints)
    }
    
    private func updateImageConstraints() {
        let imageSize = adjustedImageSize(for: image)
        imageWidthConstraint?.constant = imageSize.width
    }
    
    func adjustedImageSize(for image: UIImage?) -> CGSize {
        guard let image = image else {
            return imageSize
        }
        
        return adjustedImageWidth(for: image)
    }
    
    private func adjustedImageWidth(for image: UIImage) -> CGSize {
        let adjustedImageSize: CGSize
        let ratio = image.size.width / image.size.height
        let width = imageSize.height * ratio
        adjustedImageSize = CGSize(width: min(width, 250), height: imageSize.height)
        return adjustedImageSize
    }
}
