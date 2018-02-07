//
//  ChatService.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public enum ChatServiceError: Error {
    case invalidCredentials
    case sessionInitializing(String)
    case noSession(Error?)
}

public class ChatService: Equatable {
    private let id: String = CBData.uuidString()
    
    public static func == (lhs: ChatService, rhs: ChatService) -> Bool {
        return lhs.id == rhs.id
    }
    
    public weak var delegate: ChatServiceDelegate?
    
    private let chatterbox: Chatterbox
    private weak var viewController: ChatViewController?
    
    internal var instance: ServerInstance {
        return chatterbox.instance
    }

    private(set) var userActions: ContextualActionMessage?
    
    public var initialized: Bool {
        return userActions != nil
    }
    private var isInitializing: Bool = false
    
    init(instance: ServerInstance, delegate: ChatServiceDelegate?) {
        self.delegate = delegate
        self.chatterbox = Chatterbox(instance: instance)
        self.chatterbox.chatEventListener = self
    }
    
    // start a chat, providing a view-controller for the application to manage
    public func chatViewController(modal: Bool = false) -> ChatViewController? {
        guard !modal else {
            // FIXME: Handle modal case
            fatalError("Not yet implemented.")
        }

        let viewController = ChatViewController(chatterbox: chatterbox)
        self.viewController = viewController

        if !initialized {
            Logger.default.logFatal("User session not established - kicking that off now...")

            self.establishUserSession({ (error) in
                Logger.default.logInfo("EstablishUserSession completed: \(error == nil ? "no error" : error.debugDescription)")
            })
        }
        return viewController
    }

    public func establishUserSession(_ completion: @escaping (ChatServiceError?) -> Void) {
        guard let userCredentials = delegate?.userCredentials(for: self) else {
            Logger.default.logError("Unable to get user credentials from delegate")
            completion(ChatServiceError.invalidCredentials)
            return
        }
        
        if isInitializing {
            completion(ChatServiceError.sessionInitializing("Session is currently being initialized"))
            return
        }
        isInitializing = true
        
        let user = CBUser(id: CBData.uuidString(), token: "123abd", username: userCredentials.username, consumerId: "CONSUMER_ID_IOS", consumerAccountId: "CONSUMER_ACCOUNT_ID_IOS", password: userCredentials.password)
        let vendor = CBVendor(name: "acme", vendorId: userCredentials.vendorId, consumerId: user.consumerId, consumerAccountId: user.consumerAccountId)
        
        self.chatterbox.initializeSession(forUser: user, vendor: vendor,
            success: { message in
                Logger.default.logDebug("Session Initialized")
                
                self.userActions = message
                
                completion(nil)
                
                self.isInitializing = false
            },
            failure: { error in
                Logger.default.logDebug("Session failed to initialize: \(error.debugDescription)")
                
                self.userActions = nil
                
                completion(ChatServiceError.noSession(error))
                
                self.isInitializing = false
            })
    }
}

extension ChatService: ChatEventListener {
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTransportStatus transportStatus: TransportStatus, forChat chatId: String) {
        Logger.default.logDebug("Transport Status Changed: \(transportStatus)")
        viewController?.chatterbox(chatterbox, didReceiveTransportStatus: transportStatus, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String ) {
        Logger.default.logDebug("Session Established: \(sessionId)")
        viewController?.chatterbox(chatterbox, didEstablishUserSession: sessionId, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logDebug("Topic Started: \(topicInfo)")
        viewController?.chatterbox(chatterbox, didStartTopic: topicInfo, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logDebug("Topic Resumed: \(topicInfo)")
        viewController?.chatterbox(chatterbox, didResumeTopic: topicInfo, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logDebug("Topic Finished: \(topicInfo)")
        viewController?.chatterbox(chatterbox, didFinishTopic: topicInfo, forChat: chatId)
    }
}

extension ChatService: ChatAuthListener {
    func authorizationFailed() {
        guard let delegate = delegate else { return }
        let shouldRetry = delegate.shouldRetryAfterAuthorizationFailure(for: self)
        if shouldRetry {
            establishUserSession({ error in
                if let error = error {
                    Logger.default.logError("Error establishing user session: \(error)")
                }
            })
        } else {
            Logger.default.logError("Authorization failed, cannot continue")
            delegate.fatalError(for: self)
        }
    }
}
