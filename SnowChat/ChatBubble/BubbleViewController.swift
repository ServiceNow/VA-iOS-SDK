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
    
    lazy var responseBubbleView: BubbleView = {
        let bubble = BubbleView()
        bubble.backgroundColor = UIColor.userBubbleBackgroundColor
        
        bubble.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubble)
        NSLayoutConstraint.activate([bubble.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     bubble.topAnchor.constraint(equalTo: bubbleView.bottomAnchor)])
        
        return bubble
    }()
    
    var currentUIControl: ControlProtocol?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleView)
        NSLayoutConstraint.activate([bubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     bubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        bubbleView.backgroundColor = UIColor.agentBubbleBackgroundColor
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
        
        // add response bubble
        
        guard let adaptable = (viewController as? ControlStateAdaptable), let responseView = adaptable.responseView else {
            return
        }
        
        addBubble(forResponseView: responseView)
    }
    
    private func addMessageViewToBubble(_ messageView: UIView) {
        bubbleView.contentViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        messageView.backgroundColor = UIColor.agentBubbleBackgroundColor
        messageView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.contentView.addSubview(messageView)
        
        NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: bubbleView.contentView.leadingAnchor),
                                     messageView.trailingAnchor.constraint(equalTo: bubbleView.contentView.trailingAnchor),
                                     messageView.centerYAnchor.constraint(equalTo: bubbleView.contentView.centerYAnchor)])
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        bubbleView.invalidateIntrinsicContentSize()
    }
    
    private func addBubble(forResponseView responseView: UIView) {
        responseBubbleView.contentViewInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        responseView.backgroundColor = UIColor.userBubbleBackgroundColor
        responseView.translatesAutoresizingMaskIntoConstraints = false
        responseBubbleView.contentView.addSubview(responseView)
        NSLayoutConstraint.activate([responseView.leadingAnchor.constraint(equalTo: responseBubbleView.contentView.leadingAnchor),
                                     responseView.trailingAnchor.constraint(equalTo: responseBubbleView.contentView.trailingAnchor),
                                     responseView.centerYAnchor.constraint(equalTo: responseBubbleView.contentView.centerYAnchor)])
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        responseBubbleView.invalidateIntrinsicContentSize()
    }
}
