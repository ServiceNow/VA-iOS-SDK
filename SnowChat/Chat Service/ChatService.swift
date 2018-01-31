//
//  ChatService.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public class ChatService {
    private let chatterbox: Chatterbox
    private weak var delegate: ChatServiceDelegate?
    private weak var viewController: ChatViewController?
    
    init(instance: ServerInstance, delegate: ChatServiceDelegate) {
        self.delegate = delegate
        self.chatterbox = Chatterbox(instance: instance)
        self.chatterbox.chatEventListener = self
        //self.chatterbox.authFailureListener = self
        
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
 
        let user = CBUser(id: CBData.uuidString(), token: "123abd", username: userCredentials.username, consumerId: "CONSUMER_ID_IOS", consumerAccountId: "CONSUMER_ACCOUNT_ID_IOS", password: userCredentials.password)
        let vendor = CBVendor(name: "acme", vendorId: userCredentials.vendorId, consumerId: user.consumerId, consumerAccountId: user.consumerAccountId)
        
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
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logDebug("Topic Started: \(topicInfo)")
        
        viewController?.chatterbox(chatterbox, didStartTopic: topicInfo, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logDebug("Topic Finished: \(topicInfo)")
        
        viewController?.chatterbox(chatterbox, didFinishTopic: topicInfo, forChat: chatId)
    }
}

extension ChatService: ChatAuthListener {
    func authorizationFailed() {
        guard let delegate = delegate else { return }
        let shouldRetry = delegate.authorizationFailed()
        if shouldRetry {
            establishUserSession()
        } else {
            Logger.default.logError("Authorization failed, cannot continue")
            delegate.fatalError()
        }
    }
}
