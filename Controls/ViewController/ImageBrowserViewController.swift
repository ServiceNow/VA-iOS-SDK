//
//  ImageBrowserViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/15/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import AlamofireImage

protocol ImageBrowserDelegate: AnyObject {
    func imageBrowser(_ browser: ImageBrowserViewController, didSelectImageAt index: Int)
}

class ImageBrowserViewController: UIViewController, UIScrollViewDelegate {
    
    weak var delegate: ImageBrowserDelegate?
    private var photoURLs: [URL]?
    private var images: [UIImage]?
    private var imageDownloader: ImageDownloader?
    private var currentImage: Int {
        didSet {
            pageControl.currentPage = currentImage
        }
    }
    
    private let scrollView = UIScrollView()
    private var imageViews = [UIImageView]()
    let pageControl = UIPageControl()
    
    init(photoURLs: [URL], imageDownloader: ImageDownloader, selectedImage index: Int = 0) {
        self.photoURLs = photoURLs
        self.imageDownloader = imageDownloader
        currentImage = index
        super.init(nibName: nil, bundle: nil)
    }
    
    init(images: [UIImage], selectedImage index: Int = 0) {
        self.images = images
        currentImage = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentOffset(forCurrentImage: currentImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .plain, target: self, action: #selector(doneButtonTapped(_:)))
        view.backgroundColor = .white
        
        let urlCount = photoURLs?.count ?? 0
        let imageCount = images?.count ?? 0
        if urlCount > 1 || imageCount > 1 {
            setupPageControl()
        }
        
        setupScrollView()
        updateContentOffset(forCurrentImage: currentImage)
    }
    
    @objc func doneButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.imageBrowser(self, didSelectImageAt: currentImage)
        dismiss(animated: true, completion: nil)
    }
    
    private func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     scrollView.topAnchor.constraint(equalTo: view.topAnchor)])
        
        if photoURLs != nil {
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor).isActive = true
            setupImageViewsForPhotoURLs()
        } else if images != nil {
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            setupImageViewsForImages()
        }
        
        // forcing layout subviews so we can navigate to preselected page right away
        view.layoutIfNeeded()
    }
    
    private func setupImageViewsForImages() {
        guard let images = self.images else { return }
        images.forEach({ image in
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .white
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            if let previousView = imageViews.last {
                NSLayoutConstraint.activate([imageView.leadingAnchor.constraint(equalTo: previousView.trailingAnchor)])
            } else {
                NSLayoutConstraint.activate([imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)])
            }
            
            NSLayoutConstraint.activate([imageView.topAnchor.constraint(equalTo: view.topAnchor),
                                         imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                         imageView.widthAnchor.constraint(equalTo: view.widthAnchor)])
            
            // adding last image
            if imageViews.count == images.count - 1 {
                NSLayoutConstraint.activate([imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)])
            }
            
            imageViews.append(imageView)
        })
    }
    
    private func setupImageViewsForPhotoURLs() {
        guard let photoURLs = self.photoURLs else { return }
        photoURLs.forEach({ url in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .white
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            if let previousView = imageViews.last {
                NSLayoutConstraint.activate([imageView.leadingAnchor.constraint(equalTo: previousView.trailingAnchor)])
            } else {
                NSLayoutConstraint.activate([imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)])
            }
            
            NSLayoutConstraint.activate([imageView.topAnchor.constraint(equalTo: view.topAnchor),
                                         imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                         imageView.widthAnchor.constraint(equalTo: view.widthAnchor)])
            
            // adding last image
            if imageViews.count == photoURLs.count - 1 {
                NSLayoutConstraint.activate([imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)])
            }
            
            imageViews.append(imageView)
            imageView.af_setImage(withURL: url)
        })
    }
    
    private func setupPageControl() {
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        if #available(iOS 11, *) {
            NSLayoutConstraint.activate([pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
        } else {
            NSLayoutConstraint.activate([pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 30)])
        }
        
        if let photoURLs = photoURLs {
            pageControl.numberOfPages = photoURLs.count
        }
        
        pageControl.currentPage = currentImage
    }
    
    private func updateContentOffset(forCurrentImage index: Int) {
        var contentOffset = scrollView.contentOffset
        contentOffset.x = CGFloat(index) * scrollView.bounds.width
        scrollView.contentOffset = contentOffset
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentImage = Int(scrollView.bounds.midX / scrollView.bounds.width)
    }
}
