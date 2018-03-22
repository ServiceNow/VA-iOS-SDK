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
    
    internal func startTopic(withName topicName: String) throws {
        guard let sessionId = session?.id, let conversationId = conversationContext.systemConversationId else {
            throw ChatterboxError.invalidParameter(details: "Session must be initialized before startTopic is called")
        }
        
        conversationContext.topicName = topicName
        messageHandler = startTopicMessageHandler
        
        let startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId)
        publishMessage(startTopic)
    }
    
    internal func cancelUserConversation() {
        guard conversationContext.conversationId != nil else {
            logger.logError("endConversation with no conversation current - skipping")
            return
        }

        guard let cancelTopic = cancelTopicMessageFromContextualActions() else { return }
        
        messageHandler = { message in
            let actionMessage = ChatDataFactory.actionFromJSON(message)
            guard actionMessage.direction == .fromServer else { return }
            
            if let cancelTopic = actionMessage as? CancelUserTopicMessage,
                cancelTopic.data.direction == .fromServer {
                
                var cancelTopicReply = cancelTopic
                cancelTopicReply.data.messageId = ChatUtil.uuidString()
                cancelTopicReply.data.direction = .fromClient
                cancelTopicReply.data.sendTime = Date()
                cancelTopicReply.data.actionMessage.ready = true

                self.publishMessage(cancelTopicReply)
                
            } else if let topicFinished = actionMessage as? TopicFinishedMessage {

                self.didReceiveTopicFinishedAction(topicFinished)
                
            } else if let systemError = ChatDataFactory.controlFromJSON(message) as? SystemErrorControlMessage {
                self.logger.logError("System Error! canceling conversation: \(systemError)")
                
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
        chatEventListeners.forEach(withType: ChatEventListener.self) { listener in
            listener.chatterbox(self, didFinishTopic: topicInfo, forChat: chatId)
        }
    }
    
    internal func resumeUserTopic(topicInfo: TopicInfo) {
        showTopic {
            self.state = .userConversation
            self.setupForConversation(topicInfo: topicInfo)
            self.chatEventListeners.forEach(withType: ChatEventListener.self) { listener in
                listener.chatterbox(self, didResumeTopic: topicInfo, forChat: self.chatId)
            }
        }
    }

    internal func installPostHandshakeMessageHandler() {
        state = .topicSelection
        messageHandler = postHandshakeMessageHandler
    }
    
    private func postHandshakeMessageHandler(_ message: String) {
        
        if let subscribeMessage = ChatDataFactory.actionFromJSON(message) as? SubscribeToSupportQueueMessage {
            didReceiveSubscribeToSupportAction(subscribeMessage)
            
        } else if let topicChoices = ChatDataFactory.controlFromJSON(message) as? ContextualActionMessage {
            handshakeCompletedHandler?(topicChoices)
        }
    }
    
    private func startTopicMessageHandler(_ message: String) {
        let controlMessage = ChatDataFactory.controlFromJSON(message)
        guard controlMessage.direction == .fromServer else { return }
        
        if let topicPicker = controlMessage as? UserTopicPickerMessage {
            messageHandler = startUserTopicHandshakeHandler
            
            let outgoingMessage = selectedTopicPickerMessage(from: topicPicker)
            publishMessage(outgoingMessage)
        }
    }
    
    private func selectedTopicPickerMessage(from topicPicker: UserTopicPickerMessage) -> UserTopicPickerMessage {
        var outgoingMessage = topicPicker
        outgoingMessage.type = "consumerTextMessage"
        outgoingMessage.data.direction = .fromClient
        outgoingMessage.data.richControl?.model = ControlModel(type:"field", name: "Topic")
        outgoingMessage.data.richControl?.value = conversationContext.topicName
        
        return outgoingMessage
    }
    
    private func startUserTopicHandshakeHandler(_ message: String) {
        let actionMessage = ChatDataFactory.actionFromJSON(message)
        guard actionMessage.direction == .fromServer else { return }
        
        if actionMessage.eventType == .startUserTopic {
            if let startUserTopic = actionMessage as? StartUserTopicMessage {
                let startUserTopicReadyMessage = startTopicReadyMessage(from: startUserTopic)
                publishMessage(startUserTopicReadyMessage)
            }
        } else if actionMessage.eventType == .startedUserTopic {
            if let startUserTopicMessage = actionMessage as? StartedUserTopicMessage {
                let actionMessage = startUserTopicMessage.data.actionMessage
                
                logger.logInfo("User Topic Started: \(actionMessage.topicName) - \(actionMessage.topicId) - \(actionMessage.ready ? "Ready" : "Not Ready")")
                
                startUserTopic(topicInfo: TopicInfo(topicId: actionMessage.topicId, topicName: actionMessage.topicName, taskId: actionMessage.taskId, conversationId: actionMessage.vendorTopicId))
            }
        }
    }
    
    private func startTopicReadyMessage(from message: StartUserTopicMessage) -> StartUserTopicMessage {
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
        chatEventListeners.forEach(withType: ChatEventListener.self) { listener in
            listener.chatterbox(self, didStartTopic: topicInfo, forChat: chatId)
        }
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
