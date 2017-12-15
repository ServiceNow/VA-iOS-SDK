//
//  BubbleViewController.swift
//  Controls
//
//  Created by Michael Borowiec on 11/10/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

public class BubbleViewController: UIViewController {
    
    let bubbleView = BubbleView()
    
    lazy var responseBubbleView: BubbleView = {
        let bubble = BubbleView()
        bubble.backgroundColor = UIColor(red: 190 / 255, green: 221 / 255, blue: 239 / 255, alpha: 1)
        bubble.borderColor = UIColor.red
        
        bubble.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubble)
        NSLayoutConstraint.activate([bubble.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     bubble.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     bubble.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        
        return bubble
    }()
    
    var currentUIControl: ControlProtocol?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleView)
        NSLayoutConstraint.activate([bubbleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     bubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     bubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        
        bubbleView.backgroundColor = UIColor.white //UIColor(red: 190 / 255, green: 221 / 255, blue: 239 / 255, alpha: 1)
        bubbleView.borderColor = UIColor(red: 220 / 255, green: 225 / 255, blue: 231 / 255, alpha: 1)
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
