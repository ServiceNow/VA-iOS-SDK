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
    case noSession(Error?)
}

public class ChatService {
    
    public weak var delegate: ChatServiceDelegate?
    
    private let chatterbox: Chatterbox
    
    private weak var viewController: ChatViewController?
    
    private(set) var userActions: ContextualActionMessage?
    
    private var isInitializing: Bool = false
    
    // FIXME: What is the vendor ID for? Who defines this?
    private let vendor = ChatVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9")
    
    public init(instance: ServerInstance, delegate: ChatServiceDelegate?) {
        self.delegate = delegate
        self.chatterbox = Chatterbox(instance: instance)
        self.chatterbox.chatEventListener = self
        self.chatterbox.chatAuthListener = self
        
        // Set default log levels for debugging
        Logger.logger(for: "AMBClient").logLevel = .error
        Logger.logger(for: "Chatterbox").logLevel = .debug
    }
    
    // start a chat, providing a view-controller for the application to manage
    public func chatViewController(modal: Bool = false) -> ChatViewController {
        guard !modal else {
            // FIXME: Handle modal case
            fatalError("Not yet implemented.")
        }

        let viewController = ChatViewController(chatterbox: chatterbox)
        self.viewController = viewController
        
        return viewController
    }
    
    public func establishUserSession(token: OAuthToken, completion: @escaping (ChatServiceError?) -> Void) {
        if isInitializing {
            fatalError("Only one initialization can be performed at a time.")
        }
        
        isInitializing = true
        
        chatterbox.establishUserSession(vendor: vendor, token: token) { (result) in
            
            self.isInitializing = false
            
            switch result {
            case let .success(message):
                Logger.default.logDebug("Session Initialized")
                self.userActions = message
                completion(nil)
            case let .failure(error):
                Logger.default.logDebug("Session failed to initialize: \(error.localizedDescription)")
                self.userActions = nil
                
                // TODO: Leaking APIManager abstraction into chat service. Consider fixing this.
                if case APIManagerError.invalidToken = error {
                    completion(ChatServiceError.invalidCredentials)
                } else {
                    completion(ChatServiceError.noSession(error))
                }
            }
            
        }

    }

}

// TODO: Chatterbox should support multiple event listeners instead of proxying
extension ChatService: ChatEventListener {
    func chatterbox(_ chatterbox: Chatterbox, willStartAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        viewController?.chatterbox(chatterbox, willStartAgentChat: agentInfo, forChat: chatId)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didStartAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        viewController?.chatterbox(chatterbox, didStartAgentChat: agentInfo, forChat: chatId)
    }
    
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
    
    func chatterboxAuthenticationDidBecomeInvalid(_ chatterbox: Chatterbox) {
        delegate?.chatServiceAuthenticationDidBecomeInvalid(self)
    }
    
}
