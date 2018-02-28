//
//  CarouselViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

class CarouselViewController: UIViewController {
    
    private let collectionView = UICollectionView()
    
    private var model: CarouselControlViewModel
    
    // MARK: - Initialization
    
    init(model: PickerControlViewModel) {
        guard let carouselModel = model as? CarouselControlViewModel else { fatalError("Wrong model assigned to CarouselViewController") }
        self.model = carouselModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
