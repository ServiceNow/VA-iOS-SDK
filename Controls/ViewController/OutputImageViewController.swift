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
    var activityIndicatorView: UIActivityIndicatorView?
    var activityIndicatorConstraints = [NSLayoutConstraint]()
    
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
        setupActivityIndicatorView()
    }
    
    private func setupOutputImageView() {
        outputImageView.setContentHuggingPriority(.veryHigh, for: .horizontal)
        outputImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outputImageView)
        NSLayoutConstraint.activate([outputImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     outputImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     outputImageView.topAnchor.constraint(equalTo: view.topAnchor),
                                     outputImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        updateImageConstraints()
    }
    
    func showActivityIndicator(_ show: Bool) {
        if show == false {
            activityIndicatorView?.stopAnimating()
//            NSLayoutConstraint.deactivate(activityIndicatorConstraints)
        } else {
//            NSLayoutConstraint.activate(activityIndicatorConstraints)
            activityIndicatorView?.isHidden = false
            activityIndicatorView?.startAnimating()
        }
    }
    
    private func setupActivityIndicatorView() {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        
        activityIndicatorConstraints.append(contentsOf: [activityIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                                         activityIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                                                         activityIndicatorView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                                                         activityIndicatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
                                                         activityIndicatorView.widthAnchor.constraint(equalToConstant: 100)])
        NSLayoutConstraint.activate(activityIndicatorConstraints)
        activityIndicatorView.startAnimating()
    }
    
    private func updateImageConstraints() {
        imageViewWidthToHeightConstraint?.isActive = false
        imageViewSideConstraint?.isActive = false

        guard let image = image, image.size.height > maxImageSize.height || image.size.width > maxImageSize.width else {
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
        imageViewWidthToHeightConstraint?.isActive = true
        imageViewSideConstraint?.isActive = true
    }
}
