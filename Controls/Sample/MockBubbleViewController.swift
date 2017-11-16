//
//  MockBubbleViewController.swift
//  Controls
//
//  Created by Michael Borowiec on 11/10/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class MockBubbleViewController: UIViewController {
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Build PickerControlViewModel and inject into PickerControl
        let pickerViewModel = PickerControlViewModelAdapter.viewModel()
        let booleanPickerControler = BooleanPickerControl()
        booleanPickerControler.model = pickerViewModel
        if let pickerViewController = booleanPickerControler.viewController {
            pickerViewController.willMove(toParentViewController: self)
            addChildViewController(pickerViewController)
            pickerViewController.didMove(toParentViewController: self)
        }
    }
}
