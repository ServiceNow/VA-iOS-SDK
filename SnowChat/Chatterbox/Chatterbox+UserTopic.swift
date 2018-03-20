//
//  Chatterbox+UserTopic.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// MARK: - Chatterbox User Session Methods

extension Chatterbox {
    
    internal func startTopic(withName: String) throws {
        conversationContext.topicName = withName
        
        if let sessionId = session?.id, let conversationId = conversationContext.systemConversationId {
            messageHandler = startTopicMessageHandler
            
            let startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId)
            publishMessage(startTopic)
            
            // TODO: how do we signal an error?
        } else {
            throw ChatterboxError.invalidParameter(details: "Session must be initialized before startTopic is called")
        }
    }
    
    internal func cancelUserConversation() {
        guard conversationContext.conversationId != nil else {
            logger.logError("endConversation with no conversation current - skipping")
            return
        }

        guard let cancelTopic = cancelTopicMessageFromContextualActions() else { return }
        
        messageHandler = { message in
            self.logger.logDebug("CancelTopic handler: \(message)")
            
            if let cancelTopic = ChatDataFactory.actionFromJSON(message) as? CancelUserTopicMessage,
                cancelTopic.data.direction == .fromServer {
                var cancelTopicReply = cancelTopic
                cancelTopicReply.data.messageId = ChatUtil.uuidString()
                cancelTopicReply.data.direction = .fromClient
                cancelTopicReply.data.sendTime = Date()
                cancelTopicReply.data.actionMessage.ready = true

                self.publishMessage(cancelTopicReply)
                
            } else if let topicFinished = ChatDataFactory.actionFromJSON(message) as? TopicFinishedMessage {

                self.didReceiveTopicFinishedAction(topicFinished)
                
            } else if let systemError = ChatDataFactory.controlFromJSON(message) as? SystemErrorControlMessage {
                self.logger.logError("System Error canceling conversation: \(systemError)")
                
                guard let sessionId = self.conversationContext.sessionId,
                    let conversationId = self.conversationContext.conversationId else { return }
                
                self.didReceiveTopicFinishedAction(TopicFinishedMessage(withSessionId: sessionId, withConversationId: conversationId))
            }
        }
        
        publishMessage(cancelTopic)
    }
    
    private func cancelTopicMessageFromContextualActions() -> ContextualActionMessage? {
        guard var cancelTopic = contextualActions,
            let sessionId = conversationContext.sessionId,
            let conversationId = conversationContext.systemConversationId else { return nil }
        
        cancelTopic.type = "consumerTextMessage"
        cancelTopic.data.sessionId = sessionId
        cancelTopic.data.conversationId = conversationId
        cancelTopic.data.richControl?.value = CancelTopicControlMessage.value
        cancelTopic.data.direction = .fromClient
        cancelTopic.data.sendTime = Date()
        
        return cancelTopic
    }
    
    internal func finishTopic(_ conversationId: String) {
        let topicInfo = TopicInfo(topicId: nil, topicName: nil, taskId: nil, conversationId: conversationId)
        chatEventListener?.chatterbox(self, didFinishTopic: topicInfo, forChat: chatId)
    }
    
    internal func resumeUserTopic(topicInfo: TopicInfo) {
        showTopic {
            self.state = .userConversation
            self.setupForConversation(topicInfo: topicInfo)
            self.chatEventListener?.chatterbox(self, didResumeTopic: topicInfo, forChat: self.chatId)
        }
    }
    
    internal func installTopicSelectionMessageHandler() {
        state = .topicSelection
        messageHandler = topicSelectionMessageHandler
    }
    
    private func topicSelectionMessageHandler(_ message: String) {
        
        if let subscribeMessage = ChatDataFactory.actionFromJSON(message) as? SubscribeToSupportQueueMessage {
            didReceiveSubscribeToSupportAction(subscribeMessage)
            return
        }
        
        if let topicChoices = ChatDataFactory.controlFromJSON(message) as? ContextualActionMessage {
            handshakeCompletedHandler?(topicChoices)
        }
    }
    
    private func startTopicMessageHandler(_ message: String) {
        
        let controlMessage = ChatDataFactory.controlFromJSON(message)
        
        switch controlMessage.controlType {
        case .topicPicker:
            if let topicPicker = controlMessage as? UserTopicPickerMessage {
                if topicPicker.direction == .fromServer {
                    var outgoingMessage = topicPicker
                    outgoingMessage.type = "consumerTextMessage"
                    outgoingMessage.data.direction = .fromClient
                    outgoingMessage.data.richControl?.model = ControlModel(type:"field", name: "Topic")
                    outgoingMessage.data.richControl?.value = conversationContext.topicName
                    
                    messageHandler = startUserTopicHandshakeHandler
                    publishMessage(outgoingMessage)
                }
            }
        default:
            logger.logError("Unexpected message in StartTopic flow: \(controlMessage)")
        }
    }
    
    private func startUserTopicHandshakeHandler(_ message: String) {
        logger.logDebug("**** startUserTopicHandshake received: \(message)")
        
        let actionMessage = ChatDataFactory.actionFromJSON(message)
        
        if actionMessage.eventType == .startUserTopic {
            if let startUserTopic = actionMessage as? StartUserTopicMessage {
                
                // client and server messages are the same, so only look at server responses!
                if startUserTopic.direction == .fromServer {
                    let startUserTopicReadyMessage = createStartTopicReadyMessage(fromMessage: startUserTopic)
                    publishMessage(startUserTopicReadyMessage)
                }
            }
        } else if actionMessage.eventType == .startedUserTopic {
            if let startUserTopicMessage = actionMessage as? StartedUserTopicMessage {
                
                let actionMessage = startUserTopicMessage.data.actionMessage
                
                logger.logInfo("User Topic Started: \(actionMessage.topicName) - \(actionMessage.topicId) - \(actionMessage.ready ? "Ready" : "Not Ready")")
                
                startUserTopic(topicInfo: TopicInfo(topicId: actionMessage.topicId, topicName: actionMessage.topicName, taskId: actionMessage.taskId, conversationId: actionMessage.vendorTopicId))
            }
        }
    }
    
    private func createStartTopicReadyMessage(fromMessage message: StartUserTopicMessage) -> StartUserTopicMessage {
        var startUserTopicReady = message
        startUserTopicReady.data.messageId = ChatUtil.uuidString()
        startUserTopicReady.data.sendTime = Date()
        startUserTopicReady.data.direction = .fromClient
        startUserTopicReady.data.actionMessage.ready = true
        return startUserTopicReady
    }
    
    private func startUserTopic(topicInfo: TopicInfo) {
        state = .userConversation
        
        setupForConversation(topicInfo: topicInfo)
        chatEventListener?.chatterbox(self, didStartTopic: topicInfo, forChat: chatId)
    }
    
    private func setupForConversation(topicInfo: TopicInfo) {
        conversationContext.conversationId = topicInfo.conversationId
        conversationContext.taskId = topicInfo.taskId
        
        logger.logDebug("*** Setting topic message handler")
        installTopicMessageHandler()
    }
    
    internal func installTopicMessageHandler() {
        clearMessageHandlers()
        messageHandler = userTopicMessageHandler
    }
    
    private func userTopicMessageHandler(_ message: String) {
        logger.logDebug("userTopicMessage received: \(message)")
        
        if processEventMessage(message) != true {
            let control = ChatDataFactory.controlFromJSON(message)
            processControlMessage(control)
        }
    }
    
}
