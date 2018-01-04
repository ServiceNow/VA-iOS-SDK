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
    var activityIndicatorView: UIActivityIndicatorView?
    
    var image: UIImage? {
        didSet {
            outputImageView.image = image
            activityIndicatorView?.stopAnimating()
            activityIndicatorView?.removeFromSuperview()
            updateImageConstraints()
            view.layoutIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOutputImageView()
        setupActivityIndicatorView()
    }
    
    private func setupOutputImageView() {
        outputImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outputImageView)
        NSLayoutConstraint.activate([outputImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     outputImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     outputImageView.topAnchor.constraint(equalTo: view.topAnchor),
                                     outputImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        updateImageConstraints()
    }
    
    private func setupActivityIndicatorView() {
        // only display indicator if image was not loaded yet
        guard outputImageView.image == nil else {
            return
        }
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([activityIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     activityIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                     activityIndicatorView.widthAnchor.constraint(equalToConstant: 100)])
        self.activityIndicatorView = activityIndicatorView
        activityIndicatorView.startAnimating()
    }
    
    private func updateImageConstraints() {
        imageViewWidthToHeightConstraint?.isActive = false
        imageViewSideConstraint?.isActive = false
        guard let image = image else {
            return
        }
        
        // if image is in landscape - we will limit it horizontally. otherwise vertically.
        if image.size.height > image.size.width {
            imageViewSideConstraint = outputImageView.heightAnchor.constraint(lessThanOrEqualToConstant: maxImageSize.height)
        } else {
            imageViewSideConstraint = outputImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxImageSize.width)
        }
        
        // set width/height proportion
        let ratio = image.size.width / image.size.height
        imageViewWidthToHeightConstraint = outputImageView.heightAnchor.constraint(equalTo: outputImageView.widthAnchor, multiplier: ratio)
//        imageViewWidthToHeightConstraint?.priority = .veryHigh
        imageViewWidthToHeightConstraint?.isActive = true
        imageViewSideConstraint?.isActive = true
    }
}
