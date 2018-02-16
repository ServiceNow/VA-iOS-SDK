//
//  InputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class InputImageControl: PickerControlProtocol {
    
    var visibleItemCount: Int = 2
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    var style: PickerControlStyle
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let inputImageModel = model as? InputImageViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = inputImageModel
        self.style = .inline
    }
    
    // MARK: - PickerViewControllerDelegate
    
    func pickerViewController(_ viewController: PickerViewController, didFinishWithModel model: PickerControlViewModel) {
        guard let item = model.selectedItem else { return }
        switch item.type {
        case .takePhoto:
            print("Take a photo VC")
        case .photoLibrary:
            print("Choose from the library")
        default:
            fatalError("Not supported type")
        }
    }
    
    func pickerViewController(_ viewController: PickerViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {
        
    }
}
