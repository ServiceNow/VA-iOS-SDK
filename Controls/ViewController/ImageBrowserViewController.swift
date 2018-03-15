//
//  ImageBrowserViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/15/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import AlamofireImage

class ImageBrowserViewController: UIViewController {
    
    private var photoURLs: [URL]
    private var imageDownloader: ImageDownloader
    private var currentImage: Int = 0
    private var scrollView = UIScrollView()
    private var imageViews = [UIImageView]()
    
    init(photoURLs: [URL], imageDownloader: ImageDownloader) {
        self.photoURLs = photoURLs
        self.imageDownloader = imageDownloader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setupScrollView()
    }
    
    private func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     scrollView.topAnchor.constraint(equalTo: view.topAnchor),
                                     scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        // add UIImageViews
        photoURLs.forEach({ [weak self] url in
            guard let strongSelf = self else { return }
            
            let imageView = UIImageView()
            strongSelf.imageViews.append(imageView)
        })
    }
}
