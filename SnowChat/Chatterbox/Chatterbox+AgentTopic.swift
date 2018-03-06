//
//  Chatterbox+AgentTopic.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// MARK: - Chatterbox Live Agent Methods

extension Chatterbox {
    internal static let liveAgentTopicId: String = "brb"
    
    internal func transferToLiveAgent() {
        if let sessionId = session?.id, let conversationId = conversationContext.systemConversationId {
            state = .agentConversation
            messageHandler = startLiveAgentHandshakeHandler
            
            var startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId)
            startTopic.data.richControl?.value = "brb"
            startTopic.data.direction = .fromClient
            startTopic.data.richControl?.uiMetadata = contextualActions?.data.richControl?.uiMetadata
            
            logger.logDebug("*** Sending StartTopic message from client: conversationId=\(startTopic.data.conversationId ?? "NIL")")
            
            publishMessage(startTopic)
        } else {
            logger.logError("Session must be initialized before startTopic is called")
        }
    }
    
    internal func resumeLiveAgentTopic(conversation: Conversation) {
        // TODO: notify server that we are resuming the topic (showTopic)

        // have to reset the taskId to the last live agent message's taskId
        if let taskId = conversation.messageExchanges().last?.message.taskId {
            let topicInfo = TopicInfo(topicId: Chatterbox.liveAgentTopicId, topicName: nil, taskId: taskId, conversationId: conversation.conversationId)
            conversationContext.taskId = taskId
            startAgentTopic(topicInfo: topicInfo)
        } else {
            // cannot resume the live-agent chat without a taskId, so end it
            endAgentTopic()
        }
    }

    private func startLiveAgentHandshakeHandler(_ message: String) {
        logger.logDebug("**** startLiveAgentHandshakeHandler received: \(message)")
        
        let controlMessage = ChatDataFactory.controlFromJSON(message)
        
        if controlMessage.controlType == .text {
            logger.logDebug("*** Text Message in LiveAgentHandler")
            processControlMessage(controlMessage)
            return
        }
        
        let actionMessage = ChatDataFactory.actionFromJSON(message)
        
        if actionMessage.eventType == .startAgentChat,
            let startAgentChatMessage = actionMessage as? StartAgentChatMessage,
            startAgentChatMessage.data.actionMessage.chatStage == "ConnectToAgent" {
            
            if startAgentChatMessage.data.direction == .fromServer {
                logger.logDebug("*** ConnectToAgent Message from server: conversationId=\(startAgentChatMessage.data.conversationId ?? "NIL") topicId=\(startAgentChatMessage.data.actionMessage.topicId) taskId=\(startAgentChatMessage.data.taskId ?? "NIL")")
                
                let agentInfo = AgentInfo(agentId: "", agentAvatar: nil)
                chatEventListener?.chatterbox(self, willStartAgentChat: agentInfo, forChat: chatId)
                
                // store the taskId for this conversation
                conversationContext.taskId = startAgentChatMessage.data.taskId
                
                // send reponse message that we are ready
                let startAgentChatReadyMessage = createStartAgentChatReadyMessage(fromMessage: startAgentChatMessage)
                
                logger.logDebug("*** ConnectToAgent Message response client: conversationId=\(startAgentChatReadyMessage.data.conversationId ?? "NIL") topicId=\(startAgentChatMessage.data.actionMessage.topicId) taskId=\(startAgentChatReadyMessage.data.taskId ?? "NIL")")
                
                publishMessage(startAgentChatReadyMessage)
            } else {
                logger.logDebug("*** ConnectToAgent Message from client: Agent Topic Started!")
                
                // we got back out own start topic response, so begin the agent topic
                let conversationId = startAgentChatMessage.data.actionMessage.topicId
                let topicId = startAgentChatMessage.data.actionMessage.topicId
                let taskId = startAgentChatMessage.data.taskId
                let topicInfo = TopicInfo(topicId: topicId, topicName: "agent", taskId: taskId, conversationId: conversationId)
                startAgentTopic(topicInfo: topicInfo)
            }
        }
    }
    
    private func startAgentTopic(topicInfo: TopicInfo) {
        state = .agentConversation
        
        setupForAgentConversation(topicInfo: topicInfo)
        let agentInfo = AgentInfo(agentId: "", agentAvatar: nil)
        chatEventListener?.chatterbox(self, didStartAgentChat: agentInfo, forChat: chatId)
    }
    
    private func setupForAgentConversation(topicInfo: TopicInfo) {
        conversationContext.conversationId = topicInfo.conversationId
        conversationContext.taskId = topicInfo.taskId
        
        logger.logDebug("*** Setting topic message handler")
        installTopicMessageHandler()
    }
    
    private func endAgentTopic() {
        conversationContext.conversationId = nil
        conversationContext.taskId = nil
        
        let agentInfo = AgentInfo(agentId: "", agentAvatar: nil)
        chatEventListener?.chatterbox(self, didFinishAgentChat:agentInfo, forChat: chatId)
    }
    
    private func createStartAgentChatReadyMessage(fromMessage message: StartAgentChatMessage) -> StartAgentChatMessage {
        var startChatReady = message
        
        startChatReady.data.messageId = ChatUtil.uuidString()
        startChatReady.data.sendTime = Date()
        startChatReady.data.direction = .fromClient
        startChatReady.data.actionMessage.ready = true
        startChatReady.data.actionMessage.agent = false
        startChatReady.data.actionMessage.isAgent = false
        
        return startChatReady
    }
}
