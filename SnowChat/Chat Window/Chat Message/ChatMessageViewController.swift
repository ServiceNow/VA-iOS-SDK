//
//  ChatMessageViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import AlamofireImage

class ChatMessageViewController: UIViewController, ControlPresentable {
    
    @IBOutlet private weak var bubbleView: BubbleView!
    @IBOutlet private weak var agentImageView: UIImageView!
    @IBOutlet private weak var agentBubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bubbleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var agentImageTopConstraint: NSLayoutConstraint!
    
    private var controlHeightConstraint: NSLayoutConstraint?
    private var controlWidthConstraint: NSLayoutConstraint?
    
    private var isAgentMessage: Bool!
    private var theme: Theme!
    
    var controlCache: ControlCache?
    var resourceProvider: ControlResourceProvider?
    
    private(set) var uiControl: ControlProtocol?
    
    private var model: ChatMessageModel? {
        didSet {
            if let model = model {
                updateWithModel(model)
            }
        }
    }
    
    private func updateWithModel(_ model: ChatMessageModel) {
        guard let controlModel = model.controlModel,
            let resourceProvider = resourceProvider,
            let bubbleLocation = model.bubbleLocation,
            let control = controlCache?.control(forModel: controlModel, forResourceProvider: resourceProvider) else {
                return
        }
        
        // if previous uiControl had a delegate we will pass it over to a new control
        control.delegate = uiControl?.delegate
        addUIControl(control, at: bubbleLocation)
    }
    
    func configure(withChatMessageModel model: ChatMessageModel,
                   controlCache cache: ControlCache,
                   controlDelegate delegate: ControlDelegate,
                   resourceProvider provider: ControlResourceProvider) {
        isAgentMessage = (model.isLiveAgentConversation == true && model.bubbleLocation == .left)
        self.theme = model.theme
        self.controlCache = cache
        self.resourceProvider = provider
        self.model = model
        uiControl?.delegate = delegate
        loadAvatar()
        
        uiControl?.controlDidLoad()
    }
    
    private func loadAvatar() {
        if let provider = resourceProvider {
            
            agentImageView.af_imageDownloader = provider.imageDownloader
            
            if let avatarURL = model?.avatarURL ?? theme.avatarUrl {
                agentImageView.af_setImage(withURL: avatarURL)
            }
            
            agentImageView.addCircleMaskIfNeeded()
        }
    }
    
    private func prepareControlForReuse() {
        controlHeightConstraint?.isActive = false
        controlHeightConstraint = nil
        controlWidthConstraint?.isActive = false
        controlWidthConstraint = nil
        
        if let control = uiControl, isPresentingControl(control) {
            control.removeFromParent()
            
            if control.isReusable {
                controlCache?.cacheControl(forModel: control.model)
            }
        }
    }
    
    func prepareForReuse() {
        prepareControlForReuse()
        model = nil
        uiControl = nil
        resourceProvider = nil
        agentImageView.af_cancelImageRequest()
        agentImageView.image = nil
    }
    
    internal func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        guard uiControl?.model.id != control.model.id,
            uiControl?.model.type != control.model.type else {
            return
        }
        
        let controlViewController = control.viewController
        let controlView: UIView = controlViewController.view
        controlView.removeFromSuperview()
        
        // Remove current control if needed
        prepareControlForReuse()
        
        applyTheme(for: control, at: location)
        controlViewController.willMove(toParentViewController: self)
        addChildViewController(controlViewController)

        controlView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(controlView)
        NSLayoutConstraint.activate([controlView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     controlView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     controlView.topAnchor.constraint(equalTo: bubbleView.contentView.topAnchor),
                                     controlView.bottomAnchor.constraint(equalTo: bubbleView.contentView.bottomAnchor)])
        
        // Adjust width and height of the control if needed
        if let preferredControlSize = control.preferredContentSize {
            if preferredControlSize.width != UIViewNoIntrinsicMetric {
                controlWidthConstraint = controlView.widthAnchor.constraint(equalToConstant: preferredControlSize.width)
                controlWidthConstraint?.priority = .defaultLow
                controlWidthConstraint?.isActive = true
            }
            
            if preferredControlSize.height != UIViewNoIntrinsicMetric {
                controlHeightConstraint = controlView.heightAnchor.constraint(equalToConstant: preferredControlSize.height)
                controlHeightConstraint?.isActive = true
            }
        }
        
        updateConstraints(forLocation: location)
        
        if control.model.type == .outputImage {
            bubbleView.contentViewInsets = UIEdgeInsets.zero
        }
        
        controlViewController.didMove(toParentViewController: self)
        view.layoutIfNeeded()
        
        uiControl = control
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
    
    // MARK: Theme
    
    private func applyTheme(for control: ControlProtocol, at location: BubbleLocation) {
        let controlTheme: ControlTheme
        if location == .right {
            controlTheme = theme.controlTheme()
        } else if isAgentMessage {
            controlTheme = theme.controlThemeForAgent()
        } else {
            controlTheme = theme.controlThemeForBot()
        }
        
        control.applyTheme(controlTheme)
        
        // update bubble
        bubbleView.borderColor = controlTheme.backgroundColor
        bubbleView.backgroundColor = controlTheme.backgroundColor
        
        // Make sure that a little tail in the bubble gets colored like picker background. now it is hardcoded to white but will need to get theme color
        if control.viewController is PickerViewController {
            bubbleView.backgroundColor = UIColor.white
        }
    }
}
