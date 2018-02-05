//
//  ChatMessageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class ChatMessageViewController: UIViewController, ControlPresentable {
    
    var controlCache: ControlCache?

    var model: ChatMessageModel? {
        didSet {
            
            guard let chatModel = model else { return }
            
            var controlModel = chatModel.controlModel
            if controlModel.type == .multiPart, let auxiliaryControlModel = chatModel.auxiliaryControlModel {
                controlModel = auxiliaryControlModel
            }
            
            guard let control = controlCache?.control(forModel: controlModel) else {
                return
            }
            
            if let oldControl = uiControl, isPresentingControl(oldControl) {
                // TODO: cache it upon removing
                oldControl.removeFromParent()
            }
            
            addUIControl(control, at: chatModel.location)
            
            // if previous uiControl had a delegate we will pass it over to a new control
            control.delegate = uiControl?.delegate
            uiControl = control
        }
    }
    
    private let controlMaxWidth: CGFloat = 250
    private(set) var uiControl: ControlProtocol?
    
    @IBOutlet private weak var bubbleView: BubbleView!
    @IBOutlet private weak var agentImageView: UIImageView!
    @IBOutlet private weak var agentBubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var agentImageTopConstraint: NSLayoutConstraint!
    
    func configure(withChatMessageModel model: ChatMessageModel, controlCache cache: ControlCache, controlDelegate delegate: ControlDelegate) {
        self.controlCache = cache
        self.model = model
        uiControl?.delegate = delegate
    }
    
    func prepareForReuse() {
        if let control = uiControl, isPresentingControl(control) {
            control.removeFromParent()
            controlCache?.cacheControl(forModel: control.model)
        }
        
        uiControl = nil
    }
    
    internal func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        guard uiControl?.model.id != control.model.id,
            uiControl?.model.type != control.model.type else {
            Logger.default.logDebug("Seems like you try to readd the same model!")
            return
        }
        
        let controlViewController = control.viewController
        controlViewController.willMove(toParentViewController: self)
        addChildViewController(controlViewController)
        let controlView: UIView = controlViewController.view
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(controlView)
        
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: bubbleView.contentView.topAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: bubbleView.contentView.bottomAnchor)])
        
        // all controls but text will be limited to 250 points of width.
        // For now doing it across all class sizes. Might get adjusted when we get specs.
        if control.model.type != .text {
            controlView.widthAnchor.constraint(lessThanOrEqualToConstant: controlMaxWidth).isActive = true
        }
        
        updateConstraints(forLocation: location)
        updateBubble(forControl: control, andLocation: location)
        
        controlViewController.didMove(toParentViewController: self)
        view.layoutIfNeeded()
    }
    
    private func isPresentingControl(_ control: ControlProtocol?) -> Bool {
        guard let uiControlView = control?.viewController.view else {
            return false
        }
        
        return uiControlView.superview == bubbleView.contentView
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
