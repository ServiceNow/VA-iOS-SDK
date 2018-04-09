//
//  CarouselControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import AlamofireImage

class CarouselControl: PickerControlProtocol {
    
    var visibleItemCount: Int = PickerConstants.visibleItemCount
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    var style: PickerControlStyle
    
    weak var delegate: ControlDelegate?
    
    let resourceProvider: ControlResourceProvider
    
    // MARK: - Convenience properties
    
    private var carouselViewController: CarouselViewController {
        return viewController as! CarouselViewController
    }
    
    private var carouselViewModel: CarouselControlViewModel {
        return model as! CarouselControlViewModel
    }
    
    required init(model: ControlViewModel, resourceProvider: ControlResourceProvider) {
        self.model = model
        self.style = .carousel
        self.resourceProvider = resourceProvider
        carouselViewController.resourceProvider = resourceProvider
    }
    
    func updateViewController(withModel model: ControlViewModel) {
        carouselViewController.model = carouselViewModel
    }
    
    func pickerViewController(_ viewController: UIViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {
        
    }
}
