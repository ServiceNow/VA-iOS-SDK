//
//  CarouselViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import AlamofireImage

class CarouselViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ImageBrowserDelegate, ThemeableControl, CarouselControlViewLayoutDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var fullSizeContainerView: FullSizeScrollViewContainerView!
    @IBOutlet weak var carouselControlViewLayout: CarouselControlViewLayout!
    
    @IBOutlet weak var gradientOverlayView: GradientView!
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerSeperator: UIView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var footerSeperator: UIView!
    
    weak var delegate: PickerViewControllerDelegate?
    var resourceProvider: ControlResourceProvider?
    
    private var theme: ControlTheme?
    
    private let currentPageIndicatorTintColor = UIColor(red: 0, green: 122 / 255, blue: 255 / 255, alpha: 1)
    private let pageIndicatorTintColor = UIColor(red: 174 / 255, green: 213 / 255, blue: 255 / 255, alpha: 1)
    
    var model: CarouselControlViewModel {
        didSet {
            setupHeaderFooterViews()
            collectionView.reloadData()
            carouselControlViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - Initialization
    
    init(model: PickerControlViewModel) {
        guard let carouselModel = model as? CarouselControlViewModel else { fatalError("Wrong model assigned to CarouselViewController") }
        self.model = carouselModel
        let bundle = Bundle(for: CarouselViewController.self)
        super.init(nibName: "CarouselViewController", bundle: bundle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupGradientOverlay()
        setupHeaderFooterViews()
        carouselControlViewLayout.uiDelegate = self
    }
    
    private func setupGradientOverlay() {
        gradientOverlayView.colors = [.white, .clear, .clear, .white]
        gradientOverlayView.locations = [0, 0.15, 0.85, 1]
        gradientOverlayView.isUserInteractionEnabled = false
        gradientOverlayView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainerView.bringSubview(toFront: gradientOverlayView)
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        let bundle = Bundle(for: CarouselCollectionViewCell.self)
        collectionView.register(UINib(nibName: "CarouselCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: CarouselCollectionViewCell.cellIdentifier)
        fullSizeContainerView.scrollView = collectionView
        collectionView.reloadData()
    }
    
    private func setupHeaderFooterViews() {
        headerLabel.text = model.label
        let label = model.items[0].label
        selectButton.setTitle(label, for: .normal)
        selectButton.addTarget(self, action: #selector(doneButtonSelected(_:)), for: .touchUpInside)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        carouselControlViewLayout.invalidateLayout()
    }
    
    // MARK: UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCollectionViewCell.cellIdentifier, for: indexPath) as! CarouselCollectionViewCell
        cell.contentView.backgroundColor = .clear
        let item = model.items[indexPath.row] as! CarouselItem
        if let resourceProvider = resourceProvider {
            cell.configure(withCarouselItem: item, resourceProvider: resourceProvider)
        }
        
        return cell
    }
    
    @objc func zoomButtonTapped(_ sender: UIButton) {
        guard let point = self.collectionView?.convert(sender.center, from: sender.superview),
            let selectedIndexPath = collectionView?.indexPathForItem(at: point) else { return }
        
        zoomIn(itemAt: selectedIndexPath)
    }
    
    private func zoomIn(itemAt indexPath: IndexPath) {
        guard let imageDownloader = resourceProvider?.imageDownloader else { return }
        let urls = model.items.compactMap({ ($0 as? CarouselItem)?.attachment })
        let labels = model.items.compactMap({ $0.label })
        let browserViewController = ImageBrowserViewController(photoURLs: urls, labels: labels, imageDownloader: imageDownloader, selectedImage: indexPath.row)
        browserViewController.canSelectImage = true
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
    
    @objc func doneButtonSelected(_ sender: UIButton) {
        let selectedIndexPath = carouselControlViewLayout.focusedIndexPath
        model.selectItem(at: selectedIndexPath.row)
        delegate?.pickerViewController(self, didFinishWithModel: model)
    }
    
    // MARK: - ThemeableControl
    
    func applyTheme(_ theme: ControlTheme?) {
        self.theme = theme
        headerContainerView.backgroundColor = theme?.backgroundColor
        headerLabel.backgroundColor = theme?.backgroundColor
        headerLabel.textColor = theme?.fontColor
        headerSeperator.backgroundColor = theme?.separatorColor
        
        selectButton.backgroundColor = theme?.backgroundColor
        selectButton.setTitleColor(theme?.actionFontColor, for: .normal)
        footerSeperator.backgroundColor = theme?.separatorColor
    }
    
    // MARK: - ImageBrowserDelegate
    
    func imageBrowser(_ browser: ImageBrowserViewController, didSelectImageAt index: Int) {
        carouselControlViewLayout.selectItem(at: IndexPath(row: index, section: 0))
        model.selectItem(at: index)
        delegate?.pickerViewController(self, didFinishWithModel: model)
    }
    
    // MARK: - CarouselControlViewLayoutDelegate
    
    func carouselControlLayout(_ layout: CarouselControlViewLayout, didFocusItemAt indexPath: IndexPath) {
        let label = model.items[indexPath.row].label
        selectButton.setTitle(label, for: .normal)
    }
}
