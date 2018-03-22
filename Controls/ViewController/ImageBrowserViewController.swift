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
    func imageBrowser(_ browser: ImageBrowserViewController, didSelectImage atIndex: Int)
}

class ImageBrowserViewController: UIViewController, UIScrollViewDelegate {
    
    weak var delegate: ImageBrowserDelegate?
    private var photoURLs: [URL]
    private var imageDownloader: ImageDownloader
    private var currentImage: Int
    private var scrollView = UIScrollView()
    private var imageViews = [UIImageView]()
    
    init(photoURLs: [URL], imageDownloader: ImageDownloader, selectedImage index: Int = 0) {
        self.photoURLs = photoURLs
        self.imageDownloader = imageDownloader
        currentImage = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .plain, target: self, action: #selector(doneButtonTapped(_:)))
    }
    
    @objc func doneButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.imageBrowser(self, didSelectImage: currentImage)
        dismiss(animated: true, completion: nil)
    }
    
    private func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                         scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                         scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
                                         scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)])
        } else {
            edgesForExtendedLayout = UIRectEdge()
            NSLayoutConstraint.activate([scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                         scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                         scrollView.topAnchor.constraint(equalTo: view.topAnchor),
                                         scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        }
        
        setupImageViews()
        
        // forcing layout subviews so we can navigate to preselected page right away
        view.layoutIfNeeded()
        updateContentOffset(forCurrentImage: currentImage)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentImage = Int(scrollView.bounds.midX / scrollView.bounds.width)
    }
    
    private func setupImageViews() {
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
    
    private func updateContentOffset(forCurrentImage index: Int) {
        var contentOffset = scrollView.contentOffset
        contentOffset.x = CGFloat(index) * scrollView.bounds.width
        scrollView.contentOffset = contentOffset
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentOffset(forCurrentImage: currentImage)
    }
}
