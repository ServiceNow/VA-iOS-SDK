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
    case bottom
    
    // classic actionSheet
    case actionSheet
}

// MARK: - PickerViewControllerDelegate
// Common interface for all picker view controller (either Table style or Carousel)

protocol PickerViewControllerDelegate: AnyObject {
    
    // pickerTable:didSelectItemWithModel: is called when touch comes down on an item
    func pickerTable(_ pickerTable: PickerTableViewController, didSelectItem item: SelectableItemViewModel, forPickerModel pickerModel: PickerControlViewModel)
    
    // pickerTable:didFinishWithModel: is called when touch comes down on Done button if one exists
    func pickerTable(_ pickerTable: PickerTableViewController, didFinishWithModel model: PickerControlViewModel)
}

// MARK: - PickerControlProtocol

protocol PickerControlProtocol: ControlProtocol, PickerViewControllerDelegate {
    
    var style: PickerControlStyle { get set }
    
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel) -> UIViewController
}

extension PickerControlProtocol {
    
    // default implementation of protocol method. returns viewController based on provided style of the picker
    func viewController(forStyle style: PickerControlStyle, model: ControlViewModel) -> UIViewController {
        guard let model = model as? PickerControlViewModel else {
            fatalError("Wrong model class")
        }
        
        switch style {
        case .inline:
            let tableViewController = PickerTableViewController(model: model)
            tableViewController.delegate = self
            return tableViewController
            
        // FIXME: need to add proper stuff in here
        case .bottom, .actionSheet:
            let actionSheet = UIAlertController()
            return actionSheet
        }
    }
    
    // MARK: - PickerTableDelegate
    
    func pickerTable(_ pickerTable: PickerTableViewController, didFinishWithModel model: PickerControlViewModel) {
        delegate?.control(self, didFinishWithModel: model)
    }
}
