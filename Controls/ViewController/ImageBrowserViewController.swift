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
    
    var canSelectImage: Bool = false
    private var imageLabels: [String]
    private var titleLabel: UILabel?
    private var photoURLs = [URL]()
    private var images = [UIImage]()
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
    
    init(photoURLs: [URL], labels: [String] = [String](), imageDownloader: ImageDownloader, selectedImage index: Int = 0) {
        self.photoURLs = photoURLs
        self.imageDownloader = imageDownloader
        self.imageLabels = labels
        currentImage = index
        super.init(nibName: nil, bundle: nil)
    }
    
    init(images: [UIImage], labels: [String] = [String](), selectedImage index: Int = 0) {
        self.images = images
        currentImage = index
        self.imageLabels = labels
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
    
    private func updateNavigationButtons() {
        if canSelectImage {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(cancelButtonTapped(_:)))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Select", comment: ""), style: .plain, target: self, action: #selector(selectButtonTapped(_:)))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .plain, target: self, action: #selector(cancelButtonTapped(_:)))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        let urlCount = photoURLs.count
        let imageCount = images.count
        if urlCount > 1 || imageCount > 1 {
            setupPageControl()
        }
        
        setupScrollView()
        updateContentOffset(forCurrentImage: currentImage)
        setupTitleLabel()
        updateNavigationButtons()
    }
    
    @objc func selectButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.imageBrowser(self, didSelectImageAt: currentImage)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupTitleLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        view.addSubview(label)
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        if #available(iOS 11, *) {
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        } else {
            label.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 20).isActive = true
        }
        titleLabel = label
        updateTitleLabel()
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
        
        if photoURLs.count > 0 {
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor).isActive = true
        } else if images.count > 0 {
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
        
        pageControl.numberOfPages = photoURLs.count
        pageControl.currentPage = currentImage
    }
    
    private func setupImageViews() {
        images.forEach({ image in
            let imageView = UIImageView(image: image)
            setup(for: imageView, count: images.count)
        })
        
        photoURLs.forEach({ url in
            let imageView = UIImageView()
            imageView.af_setImage(withURL: url)
            setup(for: imageView, count: photoURLs.count)
        })
        
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
            
            // Add image view to container
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
            
            // Add container to the main scroll view
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
            
            // update title label
            updateTitleLabel()
        }
    }
    
    private func updateTitleLabel() {
        if imageLabels.count > currentImage {
            titleLabel?.text = imageLabels[currentImage]
        }
    }
}
