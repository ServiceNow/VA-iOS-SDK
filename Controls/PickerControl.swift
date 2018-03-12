//
//  PickerControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

enum PickerControlStyle: Int {
    
    // can be embedded anywhere in parent view
    case inline
    
    // is presented at the bottom of the screen
//    case bottom
    
    // classic actionSheet
//    case actionSheet
}

struct PickerConstants {
    static let visibleItemCount = 3
}

// MARK: - PickerViewControllerDelegate

// Common interface for all picker view controller (either Table style or Carousel)
protocol PickerViewControllerDelegate: AnyObject {
    
    // pickerTable:didSelectItemWithModel: is called when touch comes down on an item
    func pickerViewController(_ viewController: PickerViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel)
    
    // pickerTable:didFinishWithModel: is called when touch comes down on Done button if one exists
    func pickerViewController(_ viewController: PickerViewController, didFinishWithModel model: PickerControlViewModel)
}

// MARK: - PickerControlProtocol

protocol PickerControlProtocol: ControlProtocol, PickerViewControllerDelegate {
    
    var visibleItemCount: Int { get set }
    
    var style: PickerControlStyle { get set }
    
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel) -> UIViewController
    
    func updateViewController(withModel model: ControlViewModel)
}

// MARK: - Default PickerControl implementation

extension PickerControlProtocol {
    
    var maxContentSize: CGSize? {
        return CGSize(width: 250, height: CGFloat.nan)
    }
    
    // default implementation of protocol method. returns viewController based on provided style of the picker
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel) -> UIViewController {
        guard let model = model as? PickerControlViewModel else {
            fatalError("Wrong model class")
        }
        
        switch style {
        case .inline:
            let tableViewController = PickerViewController(model: model)
            tableViewController.delegate = self
            return tableViewController
        }
    }
    
    // MARK: - PickerTableDelegate
    
    func pickerViewController(_ viewController: PickerViewController, didFinishWithModel model: PickerControlViewModel) {
        delegate?.control(self, didFinishWithModel: model)
    }
    
    func updateViewController(withModel model: ControlViewModel) {
        guard let pickerModel = model as? PickerControlViewModel else { fatalError("Wrong model class") }
        guard let pickerViewController = viewController as? PickerViewController else { fatalError("viewController is not PickerViewController type") }
        
        pickerViewController.model = pickerModel
    }
}
