//
//  OutputImageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class OutputImageViewController: UIViewController {
    
    let outputImageView = UIImageView()
    
    var imageViewWidthToHeightConstraint: NSLayoutConstraint?
    
    var image: UIImage? {
        didSet {
            
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
    
    func setImage(_ image: UIImage) {
        // reset width to height constraint
        imageViewWidthToHeightConstraint?.isActive = false
        let ratio = image.size.width / image.size.height
        imageViewWidthToHeightConstraint = outputImageView.heightAnchor.constraint(equalTo: outputImageView.widthAnchor, multiplier: ratio)
        imageViewWidthToHeightConstraint?.priority = .veryHigh
        imageViewWidthToHeightConstraint?.isActive = true
        outputImageView.image = image
    }
}
