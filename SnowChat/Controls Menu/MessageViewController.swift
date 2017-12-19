//
//  MessageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    
    @IBOutlet weak var bubbleView: BubbleView!
    
    @IBOutlet weak var agentImageView: UIImageView!
    
    @IBOutlet weak var agentBubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleTrailingConstraint: NSLayoutConstraint!
    
    var uiControl: ControlProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bubbleView.borderColor = UIColor.agentBubbleBackgroundColor
        bubbleView.backgroundColor = UIColor.agentBubbleBackgroundColor
    }
    
    func addUIControl(_ control: ControlProtocol) {
        removeUIControl()
        uiControl = control
        
        let controlViewController = control.viewController
        controlViewController.willMove(toParentViewController: self)
        addChildViewController(controlViewController)
        
        let controlView: UIView = controlViewController.view
        controlView.backgroundColor = UIColor.agentBubbleBackgroundColor
        
        updateForControlDirection(control.model.direction)
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(controlView)
        controlViewController.didMove(toParentViewController: self)
        
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: bubbleView.contentView.topAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: bubbleView.contentView.bottomAnchor)])
    }
    
    func removeUIControl() {
        uiControl?.viewController.removeFromParentViewController()
        uiControl?.viewController.view.removeFromSuperview()
    }
    
    // updates message view based on the direction of the message
    private func updateForControlDirection(_ direction: ControlDirection) {
        switch direction {
        case .inbound:
            agentImageView.isHidden = false
            bubbleView.arrowDirection = .left
            agentBubbleLeadingConstraint.priority = .defaultHigh
            bubbleLeadingConstraint.priority = .defaultLow
            bubbleTrailingConstraint.priority = .defaultHigh
        case .outbound:
            bubbleView.arrowDirection = .right
            agentBubbleLeadingConstraint.priority = .defaultLow
            bubbleLeadingConstraint.priority = .defaultHigh
            bubbleTrailingConstraint.priority = .veryHigh
            agentImageView.isHidden = true
        }
        
        self.view.layoutIfNeeded()
    }
}
