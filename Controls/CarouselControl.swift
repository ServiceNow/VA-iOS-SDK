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
    
    var style: PickerControlStyle
    
    var model: ControlViewModel
    
    var imageDownloader: ImageDownloader?
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        self.model = model
        self.style = .carousel
    }
    
    func pickerViewController(_ viewController: PickerViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {
        
    }
}
