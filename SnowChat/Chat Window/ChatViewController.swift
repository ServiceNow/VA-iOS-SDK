//
//  ChatViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

public class ChatViewController: UIViewController {
    
    private let chatterbox: Chatterbox
    private var conversationViewController: ConversationViewController?
    
    // MARK: - Initialization
    
    internal init(chatterbox: Chatterbox) {
        self.chatterbox = chatterbox
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConversationViewController()
        setupContextMenu()
    }
    
    // MARK: - Setup
    
    private func setupConversationViewController() {
        let controller = ConversationViewController(chatterbox: chatterbox)
        
        controller.willMove(toParentViewController: self)
        addChildViewController(controller)
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.frame = view.bounds
        view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        
        conversationViewController = controller
    }
    
    private func setupContextMenu() {
        let contextMenu = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(contextMenuTapped(_:)))
        navigationItem.rightBarButtonItem = contextMenu
    }
    
    @objc func contextMenuTapped(_ sender:UIBarButtonItem!) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let contextItems = conversationViewController?.contextMenuItems()
        contextItems?.forEach({ item in
            alertController.addAction(UIAlertAction(title: item.title, style: .default) { action in
                item.handler(self, sender)
            })
        })
        
        alertController.popoverPresentationController?.barButtonItem = sender
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
}

extension ChatViewController: ChatEventListener {
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String) {
        conversationViewController?.chatterbox(chatterbox, didStartTopic: topic, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String) {
        conversationViewController?.chatterbox(chatterbox, didFinishTopic: topic, forChat: chatId)
    }
}
