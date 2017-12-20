//
//  BubbleViewController.swift
//  Controls
//
//  Created by Michael Borowiec on 11/10/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class BubbleViewController: UIViewController {
    
    let bubbleView = BubbleView(arrowDirection: .right)
    
    var currentUIControl: ControlProtocol?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleView)
        NSLayoutConstraint.activate([bubbleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     bubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     bubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        bubbleView.backgroundColor = UIColor.agentBubbleBackgroundColor
        bubbleView.borderColor = UIColor.agentBubbleBackgroundColor
    }
    
    func removeCurrentUIControl() {
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

        guard let messageView = viewController.view else {
            return
        }
        
        addMessageViewToBubble(messageView)
        viewController.didMove(toParentViewController: self)
    }
    
    private func addMessageViewToBubble(_ messageView: UIView) {
        bubbleView.contentViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        messageView.backgroundColor = UIColor.agentBubbleBackgroundColor
        messageView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(messageView)
        
        NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     messageView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     messageView.topAnchor.constraint(equalTo: bubbleView.contentView.topAnchor),
                                     messageView.bottomAnchor.constraint(equalTo: bubbleView.contentView.bottomAnchor)])
        view.setNeedsLayout()
        view.layoutIfNeeded()
        bubbleView.invalidateIntrinsicContentSize()
    }
}
