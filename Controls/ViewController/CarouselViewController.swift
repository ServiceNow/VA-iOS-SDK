//
//  CarouselViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import AlamofireImage

class CarouselViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: PickerViewControllerDelegate?
    var imageDownloader: ImageDownloader?
    
    private var collectionView: UICollectionView?
    private var gradientOverlayView = GradientView()
    private var model: CarouselControlViewModel
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
        guard let collectionView = collectionView else { return }
        gradientOverlayView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(gradientOverlayView)
        NSLayoutConstraint.activate([gradientOverlayView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
                                     gradientOverlayView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
                                     gradientOverlayView.topAnchor.constraint(equalTo: collectionView.topAnchor),
                                     gradientOverlayView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)])
    }
    
    private func setupCollectionView() {
        let layout = CarouselControlViewLayout()
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let bundle = Bundle(for: CarouselCollectionViewCell.self)
        collectionView.register(UINib(nibName: "CarouselCollectionViewCell", bundle: bundle), forCellWithReuseIdentifier: CarouselCollectionViewCell.cellIdentifier)
        collectionView.register(CarouselControlHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CarouselControlHeaderView.headerIdentifier)
        
        fullSizeContainer.scrollView = collectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(collectionView)
        NSLayoutConstraint.activate([collectionView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     collectionView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     collectionView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     collectionView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor),
                                     collectionView.heightAnchor.constraint(equalToConstant: 250)])
        
        self.collectionView = collectionView
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.reloadData()
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        model.selectItem(at: indexPath.row)
        delegate?.pickerViewController(self, didFinishWithModel: model)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CarouselControlHeaderView.headerIdentifier, for: indexPath) as! CarouselControlHeaderView
        headerView.backgroundColor = .controlHeaderBackgroundColor
        headerView.configure(with: model)
        return headerView
    }
}
