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
    private var controlWidthConstraint: NSLayoutConstraint?
    
    private(set) var uiControl: ControlProtocol?
    
    var model: ChatMessageModel? {
        didSet {
            guard let messageModel = model else {
                return
            }
            
            let control = ControlsUtil.controlForViewModel(messageModel.controlModel)
            addUIControl(control, at: messageModel.location)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bubbleView.borderColor = UIColor.agentBubbleBackgroundColor
        bubbleView.backgroundColor = UIColor.agentBubbleBackgroundColor
    }
    
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        removeUIControl()
        
        let controlViewController = control.viewController
        controlViewController.willMove(toParentViewController: self)
        addChildViewController(controlViewController)
        
        let controlView: UIView = controlViewController.view
        updateForLocation(location)
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(controlView)
        controlViewController.didMove(toParentViewController: self)
        
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: bubbleView.contentView.topAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: bubbleView.contentView.bottomAnchor)])
        
        // all controls but text will be limited to 250 points of width.
        // For now doing it across all class sizes. Might be adjusted when we get specs.
        if control.model.type != .text {
            controlView.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
        }
        
        uiControl = control
    }
    
    func removeUIControl() {
        uiControl?.viewController.removeFromParentViewController()
        uiControl?.viewController.view.removeFromSuperview()
    }
    
    // updates message view based on the direction of the message
    
    private func updateForLocation(_ location: BubbleLocation) {
        if uiControl?.model.type == .text,
            let textView = uiControl?.viewController.view as? UITextView {
            textView.textColor = (location == .right) ? UIColor.userBubbleTextColor : UIColor.agentBubbleTextColor
        }
        
        switch location {
        case .left:
            uiControl?.viewController.view.backgroundColor = UIColor.agentBubbleBackgroundColor
            bubbleView.backgroundColor = UIColor.agentBubbleBackgroundColor
            agentImageView.isHidden = false
            bubbleView.arrowDirection = .left
            agentBubbleLeadingConstraint.priority = .veryHigh
            bubbleLeadingConstraint.priority = .defaultLow
            bubbleTrailingConstraint.priority = .defaultHigh
        case .right:
            uiControl?.viewController.view.backgroundColor = UIColor.userBubbleBackgroundColor
            bubbleView.backgroundColor = UIColor.userBubbleBackgroundColor
            bubbleView.arrowDirection = .right
            agentBubbleLeadingConstraint.priority = .defaultLow
            bubbleLeadingConstraint.priority = .defaultHigh
            bubbleTrailingConstraint.priority = .veryHigh
            agentImageView.isHidden = true
        }
        
        self.view.layoutIfNeeded()
    }
}
