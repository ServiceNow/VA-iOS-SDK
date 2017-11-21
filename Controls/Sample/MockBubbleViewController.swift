//
//  MockBubbleViewController.swift
//  Controls
//
//  Created by Michael Borowiec on 11/10/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class MockBubbleViewController: UIViewController {
    
    let bubbleView = RoundedView()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        bubbleView.cornerRadius = 12
        bubbleView.corners = [.topLeft, .topRight]
        bubbleView.backgroundColor = UIColor(red: 59.0 / 255, green: 167.0 / 255, blue: 246.0 / 255, alpha: 1)
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleView)
        NSLayoutConstraint.activate([bubbleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                    bubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                    bubbleView.topAnchor.constraint(equalTo: view.topAnchor),
                                    bubbleView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)])
        
        let booleanPicker = BooleanPickerControl()
        guard let pickerViewController = booleanPicker.viewController else {
            return
        }
        
        pickerViewController.willMove(toParentViewController: self)
        addChildViewController(pickerViewController)
        pickerViewController.didMove(toParentViewController: self)
        
        guard let pickerBooleanView = pickerViewController.view else {
            return
        }
        
        pickerBooleanView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerBooleanView)
        
        NSLayoutConstraint.activate([pickerBooleanView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     pickerBooleanView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     pickerBooleanView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                     pickerBooleanView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor)])
    }
}
