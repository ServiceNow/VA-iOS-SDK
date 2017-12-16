//
//  MessageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    
    // self.view..
    var messageView = MessageView.fromNib() as! MessageView
    
    var uiControl: ControlProtocol?
    
    override func loadView() {
        self.view = messageView
    }
    
    func addUIControl(_ control: ControlProtocol) {
        uiControl = control
        
        let viewController = control.viewController
        viewController.willMove(toParentViewController: self)
        addChildViewController(viewController)
        
        let controlView: UIView = viewController.view
        let bubbleView: BubbleView = messageView.bubbleView
        bubbleView.borderColor = UIColor.agentBubbleBackgroundColor
        bubbleView.backgroundColor = UIColor.agentBubbleBackgroundColor
        controlView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(controlView)
        
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     controlView.centerYAnchor.constraint(equalTo: bubbleView.contentView.centerYAnchor)])
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        bubbleView.invalidateIntrinsicContentSize()
        viewController.didMove(toParentViewController: self)
    }
    
    func removeUIControl() {
        guard let uiControl = uiControl else {
            return
        }
        
        uiControl.viewController.removeFromParentViewController()
        uiControl.viewController.view.removeFromSuperview()
    }
}
