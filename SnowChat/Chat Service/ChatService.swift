//
//  ChatService.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public class ChatService {
    private let chatterbox = Chatterbox()
    private weak var delegate: ChatServiceAppDelegate?
    private weak var viewController: ChatViewController?
    
    init(delegate: ChatServiceAppDelegate) {
        self.delegate = delegate
        self.chatterbox.chatEventListener = self
        
        establishUserSession()
    }
    
    // // start a chat, providing a view-controller for the application to manage
    public func chatViewController(modal: Bool = false) -> ChatViewController {
        if modal {
            // FIXME: Handle modal case
            fatalError("Not yet implemented.")
        }
        
        let viewController = ChatViewController(chatterbox: chatterbox)
        self.viewController = viewController
        return viewController
    }

    private func establishUserSession() {
        guard let userCredentials = delegate?.userCredentials() else {
            Logger.default.logError("Unable to get user credentials from delegate")
            return
        }
 
        let user = CBUser(id: CBData.uuidString(), token: "123abd", name: userCredentials.userName, consumerId: userCredentials.consumerId, consumerAccountId: userCredentials.consumerAccountId, password: userCredentials.userPassword)
        let vendor = CBVendor(name: "acme", vendorId: userCredentials.vendorId, consumerId: userCredentials.consumerId, consumerAccountId: userCredentials.consumerAccountId)
        
        chatterbox.initializeSession(forUser: user, vendor: vendor, success: { message in
            Logger.default.logDebug("Session Initialized")
            
            if let options = message.data.richControl?.uiMetadata?.inputControls.first?.uiMetadata?.options {
                options.forEach({ (option) in
                    Logger.default.logDebug(option.label)
                })
            } else {
                Logger.default.logDebug("Session initialized but no valid ContexztualActionMessage received!")
            }

        }, failure: { error in
            Logger.default.logDebug("Session failed to initialize: \(error.debugDescription)")

        })
    }
}

extension ChatService: ChatEventListener {
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String) {
        Logger.default.logDebug("Topic Started: \(topic)")
        
        viewController?.chatterbox(chatterbox, didStartTopic: topic, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String) {
        Logger.default.logDebug("Topic Finished: \(topic)")
        
        viewController?.chatterbox(chatterbox, didFinishTopic: topic, forChat: chatId)
    }
}
