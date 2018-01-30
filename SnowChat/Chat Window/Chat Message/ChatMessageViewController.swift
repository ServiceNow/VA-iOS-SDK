//
//  ChatMessageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ChatMessageViewController: UIViewController {
    
    private let controlMaxWidth: CGFloat = 250
    private(set) var uiControl: ControlProtocol?
    
    @IBOutlet private weak var bubbleView: BubbleView!
    @IBOutlet private weak var agentImageView: UIImageView!
    @IBOutlet private weak var agentBubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var agentImageTopConstraint: NSLayoutConstraint!
    
    private weak var initialControlHeight: NSLayoutConstraint?
    private weak var topControlConstraint: NSLayoutConstraint!
    
    func resizeBubbleToFitControl(animated: Bool) {
        // prepare control for animation with its initial height
        initialControlHeight?.isActive = true
        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
        
        // ..and now animate control to its regular height
        initialControlHeight?.isActive = false
//        UIView.animate(withDuration: 10,
//                       delay: 0,
//                       usingSpringWithDamping: 0.9,
//                       initialSpringVelocity: 0,
//                       options: .curveEaseOut,
//                       animations: {
//                        self.view.layoutIfNeeded()
//        },
//                       completion: nil)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        guard uiControl?.model.id != control.model.id,
            uiControl?.model.type != control.model.type else {
            Logger.default.logDebug("Seems like you try to readd the same model!")
            return
        }
        
        // capture initial height of the control so we can use it for animation of the new control
        let currentControlHeight = uiControl?.viewController.view.frame.height ?? 20
        let resizeBubbleImmediately = uiControl != nil
        
        removeUIControl()
        uiControl = control
        updateConstraints(forLocation: location)
        updateBubble(forControl: control, andLocation: location)
        
        let controlViewController = control.viewController
        controlViewController.willMove(toParentViewController: self)
        addChildViewController(controlViewController)
        let controlView: UIView = controlViewController.view
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(controlView)
        topControlConstraint = controlView.topAnchor.constraint(equalTo: bubbleView.contentView.topAnchor)
        topControlConstraint.priority = .veryHigh
        
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     topControlConstraint,
                                     controlView.bottomAnchor.constraint(equalTo: bubbleView.contentView.bottomAnchor)])

        // all controls but text will be limited to 250 points of width.
        // For now doing it across all class sizes. Might get adjusted when we get specs.
        if control.model.type != .text {
            controlView.widthAnchor.constraint(lessThanOrEqualToConstant: controlMaxWidth).isActive = true
        }
        
        controlViewController.didMove(toParentViewController: self)

        // This will make sure that cell is resized to a final height of the control which we want
        view.layoutIfNeeded()
        
        initialControlHeight = controlView.heightAnchor.constraint(equalToConstant: currentControlHeight)
        if resizeBubbleImmediately {
            resizeBubbleToFitControl(animated: true)
        }
    }
    
    func prepareForReuse() {
        removeUIControl()
        initialControlHeight?.isActive = false
        initialControlHeight = nil
    }
    
    private func removeUIControl() {
        uiControl?.viewController.removeFromParentViewController()
        uiControl?.viewController.view.removeFromSuperview()
        uiControl = nil
    }
    
    // MARK: - Update Constraints
    
    private func updateConstraints(forLocation location: BubbleLocation) {
        switch location {
        case .left:
            agentImageView.isHidden = false
            bubbleView.arrowDirection = .left
            agentBubbleLeadingConstraint.priority = .veryHigh
            bubbleLeadingConstraint.priority = .defaultLow
            bubbleTrailingConstraint.priority = .defaultHigh
            agentImageTopConstraint.priority = .veryHigh
        case .right:
            bubbleView.arrowDirection = .right
            agentBubbleLeadingConstraint.priority = .defaultLow
            bubbleLeadingConstraint.priority = .defaultHigh
            bubbleTrailingConstraint.priority = .veryHigh
            agentImageView.isHidden = true
            agentImageTopConstraint.priority = .lowest
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    // MARK: Update colors
    
    private func updateBubble(forControl control: ControlProtocol, andLocation location: BubbleLocation) {
        bubbleView.borderColor = UIColor.agentBubbleBackgroundColor
        
        if control.model.type == .text {
            let textViewController = control.viewController as! TextControl.TextViewController
            textViewController.textLabel.textColor = (location == .right) ? UIColor.userBubbleTextColor : UIColor.agentBubbleTextColor
            textViewController.textLabel.backgroundColor = (location == .right) ? UIColor.userBubbleBackgroundColor : UIColor.agentBubbleBackgroundColor
        }
        
        control.viewController.view.backgroundColor = (location == .right) ? UIColor.userBubbleBackgroundColor : UIColor.agentBubbleBackgroundColor
        bubbleView.backgroundColor = (location == .right) ? UIColor.userBubbleBackgroundColor : UIColor.agentBubbleBackgroundColor
        
        // Make sure that a little tail in the bubble gets colored like picker background. now it is hardcoded to white but will need to get theme color
        if control.viewController is PickerViewController {
            bubbleView.backgroundColor = UIColor.white
        }
    }
}
