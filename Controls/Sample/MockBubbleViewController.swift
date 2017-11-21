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
    var currentUIControl: ControlProtocol?
    
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
    }
    
    private func removeCurrentUIControl() {
        guard let currentUIControl = currentUIControl else {
            return
        }
        
        currentUIControl.viewController.removeFromParentViewController()
        currentUIControl.viewController.view.removeFromSuperview()
    }
    
    func addUIControl(_ control: ControlProtocol) {
        removeCurrentUIControl()
        currentUIControl = control
        
        let viewController = control.viewController
        viewController.willMove(toParentViewController: self)
        addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
        
        guard let controlView = viewController.view else {
            return
        }
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlView)
        
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                     controlView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor)])
    }
}
