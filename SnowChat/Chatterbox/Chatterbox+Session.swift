//
//  Chatterbox+Session.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// MARK: - Chatterbox Session Methods

extension Chatterbox {

    func establishUserSession(vendor: ChatVendor, token: OAuthToken, userContextData contextData: Codable? = nil, completion: @escaping (Result<ContextualActionMessage>) -> Void) {
        self.userContextData = contextData
        self.vendor = vendor
        
        apiManager.prepareUserSession(token: token) { [weak self] result in
            guard let strongSelf = self else { return }
            guard result.error == nil else {
                if let error = result.error {
                    completion(.failure(error))
                }
                return
            }
            
            strongSelf.createChatSession(vendor: vendor) { [weak self] error in
                guard let strongSelf = self else { return }
                guard error == nil else {
                    if let error = error {
                        completion(.failure(error))
                    }
                    return
                }
                
                strongSelf.performChatHandshake { [weak self] actionMessage in
                    guard let strongSelf = self else { return }
                    guard let actionMessage = actionMessage, let sessionId = strongSelf.session?.id else {
                        completion(.failure(ChatterboxError.unknown(details: "Chat Handshake failed for an unknown reason")))
                        return
                    }
                    
                    strongSelf.contextualActions = actionMessage
                    strongSelf.state = .topicSelection

                    strongSelf.notifyEventListeners { listener in
                        listener.chatterbox(strongSelf, didEstablishUserSession:  sessionId, forChat: strongSelf.chatId)
                    }
                    
                    completion(.success(actionMessage))
                }
            }
        }
    }
    
    func updateUserSession(token: OAuthToken, completion: @escaping (Result<ContextualActionMessage>) -> Void) {
        guard let sessionId = session?.id,
            let actionMessage = contextualActions else {
                logger.logError("updateUserSession requires an existing user session and chat session!")
                completion(.failure(ChatterboxError.illegalState(details: "Previous chat handshake required")))
                return
        }
        
        apiManager.updateUserSession(token: token) { [weak self] result in
            guard let strongSelf = self else { return }
            
            guard result.error == nil else {
                if let error = result.error {
                    completion(.failure(error))
                }
                return
            }
            
            strongSelf.notifyEventListeners { listener in
                listener.chatterbox(strongSelf, didRestoreUserSession: sessionId, forChat: strongSelf.chatId)
            }
            
            completion(.success(actionMessage))
        }
    }
    
    private func createChatSession(vendor: ChatVendor, completion: @escaping (Error?) -> Void) {
        let sessionContext = ChatSessionContext(vendor: vendor)
        
        apiManager.startChatSession(with: sessionContext, chatId: chatId) { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let session):
                strongSelf.session = session
                
                strongSelf.logger.logDebug("--> Chat Session established: sessionId: \(strongSelf.session?.id ?? "NIL") \n consumerAccountId=\(session.user.consumerAccountId)")
            case .failure:
                strongSelf.logger.logError("getSession failed!")
            }
            completion(result.error)
        }
    }
    
    private func setupChatSubscription() {
        chatSubscription = apiManager.ambClient.subscribe(channel: chatChannel) { [weak self] (result, subscription) in
            guard let strongSelf = self else { return }
            guard let messageHandler = strongSelf.messageHandler else {
                strongSelf.logger.logError("No handler set in Chatterbox setupChatSubscription!")
                return
            }
            
            switch result {
            case .success:
                if let message = result.value {
                    let messageString = message.jsonDataString
                    
                    strongSelf.logger.logDebug("Received from AMB: \(messageString)")
                    
                    // FIRST we check for a general system events (system error, updated ContextualAction, etc)
                    let systemError = ChatDataFactory.controlFromJSON(messageString)
                    guard systemError.controlType != .systemError else {
                        strongSelf.logger.logError("System Error received")
                        strongSelf.didReceiveSystemError(messageString)
                        return
                    }
                    
                    messageHandler(messageString)
                } else {
                    fatalError("AMB Success with no result value!")
                }
            case .failure:
                if let error = result.error {
                    strongSelf.logger.logError("AMB error: \(error)")
                }
                // TODO: how to handle AMB errors here?
            }
        }
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage?) -> Void) {
        handshakeCompletedHandler = completion
        messageHandler = handshakeMessageHandler
        
        setupChatSubscription()
        
        if let sessionId = session?.id {
            publishMessage(SystemTopicPickerMessage(forSession: sessionId))
        }
    }
    
    private func startUserSession(withInitEvent initEvent: InitMessage) {
        var initUserEvent = userSessionInitMessage(fromInitEvent: initEvent)
        if let request = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            appContextManager.setupHandlers(for: request)
            appContextManager.authorizeContextItems(for: request, completion: { [weak self] response in
                initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = response

                self?.appContextManager.fetchContextData(with: self?.userContextData, completion: { [weak self] contextData in
                    initUserEvent.data.actionMessage.contextData = contextData
                    self?.publishMessage(initUserEvent)
                })
            })
        } else {
            publishMessage(initUserEvent)
        }
    }
    
    private func userSessionInitMessage(fromInitEvent initEvent: InitMessage) -> InitMessage {
        var initUserEvent = initEvent
        
        initUserEvent.data.direction = .fromClient
        initUserEvent.data.sendTime = Date()
        initUserEvent.data.actionMessage.loginStage = .loginUserSession
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor?.vendorId
        initUserEvent.data.actionMessage.userId = user?.consumerId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = deviceIdentifier()
        initUserEvent.data.actionMessage.consumerAcctId = session?.user.consumerAccountId
        initUserEvent.data.actionMessage.extId = (initUserEvent.data.actionMessage.contextHandshake.deviceId ?? "") + (session?.user.consumerAccountId ?? "")
        return initUserEvent
    }
    
    private func handshakeMessageHandler(_ message: String) {
        let event = ChatDataFactory.actionFromJSON(message)
        guard event.eventType == .channelInit,
            let initEvent = event as? InitMessage else {
                return
        }
        
        switch initEvent.data.actionMessage.loginStage {
        case .loginStart:
            logger.logDebug("Handshake START message received")
            startUserSession(withInitEvent: initEvent)
        case .loginFinish:
            logger.logDebug("Handshake FINISH message received: conversationID=\(initEvent.data.conversationId ?? "nil")")
            
            conversationContext.systemConversationId = initEvent.data.conversationId
            conversationContext.sessionId = initEvent.data.sessionId
            
            installPostHandshakeMessageHandler()
        default:
            break
        }
    }
}
