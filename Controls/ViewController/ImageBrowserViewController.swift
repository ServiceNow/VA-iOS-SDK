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
            if oldValue != currentImage {
                resetZoom(for: oldValue)
            }
        }
    }
    
    private let scrollView = UIScrollView()
    private var imageViews = [UIImageView]()
    private var isZoomed: Bool = false
    private let doubleTapGestureRecognizer = UITapGestureRecognizer()
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
    
    private func resetZoom(for imageIndex: Int) {
        let imageView = imageViews[imageIndex]
        UIView.performWithoutAnimation {
            imageView.transform = CGAffineTransform.identity
            let scrollView = (imageView.superview as? UIScrollView)
            scrollView?.layoutIfNeeded()
            scrollView?.setZoomScale(1, animated: false)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resetZoom(for: currentImage)
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
        } else if images != nil {
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        setupImageViews()
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(doubleTappedImageView(_:)))
        
        // forcing layout subviews so we can navigate to preselected page right away
        view.layoutIfNeeded()
    }
    
    @objc func doubleTappedImageView(_ gesture: UITapGestureRecognizer) {
        isZoomed = !isZoomed
        if let containerImageView = imageViews[currentImage].superview as? UIScrollView {
            let maxZoomScale = containerImageView.maximumZoomScale
            containerImageView.setZoomScale(isZoomed ? maxZoomScale : 1, animated: true)
        }
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
    
    private func setupImageViews() {
        if let images = self.images {
            images.forEach({ image in
                let imageView = UIImageView(image: image)
                setup(for: imageView, count: images.count)
            })
        }
        
        if let photoURLs = self.photoURLs {
            photoURLs.forEach({ url in
                let imageView = UIImageView()
                imageView.af_setImage(withURL: url)
                setup(for: imageView, count: photoURLs.count)
            })
        }
        
        func setup(for imageView: UIImageView, count: Int) {
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .white
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let containerView = UIScrollView()
            containerView.delegate = self
            containerView.bouncesZoom = false
            containerView.showsHorizontalScrollIndicator = false
            containerView.showsVerticalScrollIndicator = false
            containerView.maximumZoomScale = 2
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)
            
            NSLayoutConstraint.activate([imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                                         imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                                         imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                                         imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor)])
            
            scrollView.addSubview(containerView)
            if let previousView = imageViews.last?.superview {
                NSLayoutConstraint.activate([containerView.leadingAnchor.constraint(equalTo: previousView.trailingAnchor)])
            } else {
                NSLayoutConstraint.activate([containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)])
            }
            
            NSLayoutConstraint.activate([containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                                         containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                                         containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                                         containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)])
            
            // adding last image
            if imageViews.count == count - 1 {
                NSLayoutConstraint.activate([containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)])
            }
            
            imageViews.append(imageView)
        }
    }
    
    private func updateContentOffset(forCurrentImage index: Int) {
        var contentOffset = scrollView.contentOffset
        contentOffset.x = CGFloat(index) * scrollView.bounds.width
        scrollView.contentOffset = contentOffset
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard self.scrollView != scrollView, imageViews.count > currentImage else {
            return nil
        }
        
        let imageView = imageViews[currentImage]
        return imageView
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView {
            currentImage = Int(scrollView.bounds.midX / scrollView.bounds.width)
        }
    }
}
