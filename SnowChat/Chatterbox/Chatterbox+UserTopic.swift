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
    
    func endUserConversation() {
        let sessionId = conversationContext.sessionId ?? "UNKNOWN_SESSION_ID"
        let conversationId = conversationContext.conversationId ?? "UNKNOWN_CONVERSATION_ID"
        
        didReceiveTopicFinishedAction(TopicFinishedMessage(withSessionId: sessionId, withConversationId: conversationId))
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
