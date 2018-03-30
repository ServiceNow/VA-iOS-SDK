//
//  CarouselViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import AlamofireImage

class CarouselViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ImageBrowserDelegate, ThemeableControl {
    
    weak var delegate: PickerViewControllerDelegate?
    var imageDownloader: ImageDownloader?
    
    private var collectionView: UICollectionView?
    private var gradientOverlayView = GradientView()
    private var theme: ControlTheme?
    
    private let currentPageIndicatorTintColor = UIColor(red: 0, green: 122 / 255, blue: 255 / 255, alpha: 1)
    private let pageIndicatorTintColor = UIColor(red: 174 / 255, green: 213 / 255, blue: 255 / 255, alpha: 1)
    
    private var carouselControlViewLayout: CarouselControlViewLayout {
        return collectionView?.collectionViewLayout as! CarouselControlViewLayout
    }
    
    var model: CarouselControlViewModel {
        didSet {
            let layout = CarouselControlViewLayout()
            collectionView?.collectionViewLayout = layout
            collectionView?.reloadData()
        }
    }
    
    private let fullSizeContainer = FullSizeScrollViewContainerView()
    
    // MARK: - Initialization
    
    init(model: PickerControlViewModel) {
        guard let carouselModel = model as? CarouselControlViewModel else { fatalError("Wrong model assigned to CarouselViewController") }
        self.model = carouselModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func loadView() {
        self.view = fullSizeContainer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupGradientOverlay()
    }
    
    private func setupGradientOverlay() {
        guard let collectionViewLayout = collectionView?.collectionViewLayout as? CarouselControlViewLayout else { return }
        gradientOverlayView.colors = [.white, .clear, .clear, .white]
        gradientOverlayView.locations = [0, 0.15, 0.85, 1]
        gradientOverlayView.isUserInteractionEnabled = false
        gradientOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientOverlayView)
        NSLayoutConstraint.activate([gradientOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     gradientOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     gradientOverlayView.topAnchor.constraint(equalTo: view.topAnchor, constant: collectionViewLayout.headerHeight),
                                     gradientOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -collectionViewLayout.footerHeight)])
        view.bringSubview(toFront: gradientOverlayView)
    }
    
    private func setupCollectionView() {
        let layout = CarouselControlViewLayout()
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Scroll view inside scroll view is...pretty ugly. Especially when adjustment is on!
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let bundle = Bundle(for: CarouselCollectionViewCell.self)
        collectionView.register(UINib(nibName: "CarouselCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: CarouselCollectionViewCell.cellIdentifier)
        collectionView.register(CarouselControlHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CarouselControlHeaderView.headerIdentifier)
        collectionView.register(CarouselControlFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CarouselControlFooterView.footerIdentifier)
        
        fullSizeContainer.scrollView = collectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(collectionView)
        NSLayoutConstraint.activate([collectionView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     collectionView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     collectionView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     collectionView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor),
                                     collectionView.heightAnchor.constraint(equalToConstant: 300)])
        
        self.collectionView = collectionView
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // center on the focused index path. When we first launch Carousel we want to center the first item
        let focusedIndexPath = (collectionView?.collectionViewLayout as? CarouselControlViewLayout)?.focusedIndexPath ?? IndexPath(item: 0, section: 0)
        collectionView?.selectItem(at: focusedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
    }
    
    // MARK: UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCollectionViewCell.cellIdentifier, for: indexPath) as! CarouselCollectionViewCell
        cell.contentView.backgroundColor = .clear
        let item = model.items[indexPath.row] as! CarouselItem
        if let imageDownloader = imageDownloader {
            cell.configure(withCarouselItem: item, imageDownloader: imageDownloader)
        }
        
        return cell
    }
    
    @objc func zoomButtonTapped(_ sender: UIButton) {
        guard let point = self.collectionView?.convert(sender.center, from: sender.superview),
            let selectedIndexPath = collectionView?.indexPathForItem(at: point) else { return }
        
        zoomIn(itemAt: selectedIndexPath)
    }
    
    private func zoomIn(itemAt indexPath: IndexPath) {
        guard let imageDownloader = imageDownloader else { return }
        let urls = model.items.flatMap({ ($0 as? CarouselItem)?.attachment })
        let browserViewController = ImageBrowserViewController(photoURLs: urls, imageDownloader: imageDownloader, selectedImage: indexPath.row)
        browserViewController.delegate = self
        browserViewController.pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        browserViewController.pageControl.pageIndicatorTintColor = pageIndicatorTintColor
        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let comparisonResult = carouselControlViewLayout.focusedIndexPath.compare(indexPath)
        switch comparisonResult {
        case .orderedSame:
            zoomIn(itemAt: indexPath)
        case .orderedAscending:
            carouselControlViewLayout.selectNextItem()
        case .orderedDescending:
            carouselControlViewLayout.selectPreviousItem()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CarouselControlHeaderView.headerIdentifier, for: indexPath) as! CarouselControlHeaderView
            headerView.backgroundColor = theme?.backgroundColor
            headerView.titleLabel.backgroundColor = theme?.backgroundColor
            headerView.dividerView.backgroundColor = theme?.dividerColor
            headerView.configure(with: model)
            return headerView
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CarouselControlFooterView.footerIdentifier, for: indexPath) as! CarouselControlFooterView
            footerView.backgroundColor = theme?.backgroundColor
            footerView.selectButton.setTitleColor(theme?.actionFontColor, for: .normal)
            footerView.selectButton.addTarget(self, action: #selector(doneButtonSelected(_:)), for: .touchUpInside)
            footerView.dividerView.backgroundColor = theme?.dividerColor
            return footerView
        default:
            fatalError("Unexpected kind: \(kind)")
        }
    }
    
    @objc func doneButtonSelected(_ sender: UIButton) {
        let selectedIndexPath = carouselControlViewLayout.focusedIndexPath
        model.selectItem(at: selectedIndexPath.row)
        delegate?.pickerViewController(self, didFinishWithModel: model)
    }
    
    // MARK: - ThemeableControl
    
    func applyTheme(_ theme: ControlTheme?) {
        self.theme = theme
    }
    
    // MARK: - ImageBrowserDelegate
    
    func imageBrowser(_ browser: ImageBrowserViewController, didSelectImageAt index: Int) {
        carouselControlViewLayout.selectItem(at: IndexPath(row: index, section: 0))
    }
}
