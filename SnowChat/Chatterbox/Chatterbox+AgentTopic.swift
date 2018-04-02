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
        guard let isActive = supportQueueInfo?.active, isActive == true else {
            showLiveAgentUnavailableMessage()
            return
        }
        
        cancelPendingExchangeIfNeeded()
        
        if let sessionId = session?.id, let conversationId = conversationContext.systemConversationId {
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
    
    internal func endAgentConversation() {
        guard let sessionId = conversationContext.sessionId,
            let systemConversationId = conversationContext.systemConversationId,
            let topicId = conversationContext.conversationId else {
                return
        }
        
        let endChatMessage = EndAgentChatMessage(withTopicId: topicId, systemConversationId: systemConversationId, sessionId: sessionId)        
        publishMessage(endChatMessage)
    }
    
    internal func resumeLiveAgentTopic(conversation: Conversation) {
        showTopic {
            guard let conversationId = self.conversationContext.conversationId,
                var taskId = self.conversationContext.taskId else {
                    self.endAgentTopic()
                    return
            }
            
            // FIXME: have to get the taskId from the last message in history, since the server is sending the incorrect
            //        taskId in the showTopic response. Remove when server fixes this!
            if let correctTaskId = conversation.messageExchanges().last?.message.taskId {
                self.logger.logDebug("*** Resume LiveAgent conversation: original taskId=\(correctTaskId) - incoming taskId=\(taskId) ***")

                self.conversationContext.taskId = correctTaskId
                taskId = correctTaskId
            }

            let topicInfo = TopicInfo(topicId: Chatterbox.liveAgentTopicId, topicName: nil, taskId: taskId, conversationId: conversationId)
            self.startAgentTopic(topicInfo: topicInfo)

            var agentInfo: SenderInfo?
            
            // get the agent messages and see if the conversation has been accepted by an agent yet
            let agentMessages = conversation.messageExchanges().flatMap({ (exchange) -> ControlData? in
                let message = exchange.message
                if let isAgent = message.isAgent, isAgent == true {
                    return message
                }
                return nil
            })
            
            guard agentMessages.count > 0 else { return }
            
            self.state = .agentConversation
            agentInfo = agentMessages.first?.senderInfo
            
            self.notifyEventListeners { listener in
                let agentInfo = AgentInfo(agentId: agentInfo?.name ?? AgentInfo.IDUNKNOWN,
                                          agentAvatar: agentInfo?.avatarPath)
                listener.chatterbox(self, didResumeAgentChat: agentInfo, forChat: self.chatId)
            }
        }
    }

    private func startLiveAgentHandshakeHandler(_ message: String) {
        logger.logDebug("**** startLiveAgentHandshakeHandler received: \(message)")
        
        let controlMessage = ChatDataFactory.controlFromJSON(message)
        
        if controlMessage.controlType == .text {
            logger.logDebug("*** Text Message in LiveAgentHandler")
            
            if let conversationId = controlMessage.conversationId {
                processIncomingControlMessage(controlMessage, forConversation: conversationId)
            }
            return
        }
        
        let actionMessage = ChatDataFactory.actionFromJSON(message)
        
        if actionMessage.eventType == .startAgentChat,
            let startAgentChatMessage = actionMessage as? StartAgentChatMessage,
            startAgentChatMessage.data.actionMessage.chatStage == "ConnectToAgent" {
            
            if startAgentChatMessage.direction == .fromServer {
                logger.logDebug("*** ConnectToAgent Message from server: conversationId=\(startAgentChatMessage.data.conversationId ?? "NIL") topicId=\(startAgentChatMessage.data.actionMessage.topicId) taskId=\(startAgentChatMessage.data.taskId ?? "NIL")")
                
                let agentInfo = AgentInfo(agentId: "", agentAvatar: nil)
                notifyEventListeners { listener in
                    listener.chatterbox(self, willStartAgentChat: agentInfo, forChat: chatId)
                }
                
                // store the taskId for this conversation
                conversationContext.taskId = startAgentChatMessage.data.taskId
                
                // send reponse message that we are ready
                let startAgentChatReadyMessage = createStartAgentChatReadyMessage(fromMessage: startAgentChatMessage)
                
                logger.logDebug("*** ConnectToAgent Message response client: conversationId=\(startAgentChatReadyMessage.data.conversationId ?? "NIL") topicId=\(startAgentChatMessage.data.actionMessage.topicId) taskId=\(startAgentChatReadyMessage.data.taskId ?? "NIL")")
                
                publishMessage(startAgentChatReadyMessage)
            } else {
                logger.logDebug("*** ConnectToAgent Message from client: Agent Topic Started!")
                
                // we got back out own start topic response, so we are now in the queue waiting for an 
                let conversationId = startAgentChatMessage.data.actionMessage.topicId
                let topicId = startAgentChatMessage.data.actionMessage.topicId
                let taskId = startAgentChatMessage.data.taskId
                let topicInfo = TopicInfo(topicId: topicId, topicName: "agent", taskId: taskId, conversationId: conversationId)
                startAgentTopic(topicInfo: topicInfo)
            }
        }
    }
    
    private func startAgentTopic(topicInfo: TopicInfo) {
        state = .waitingForAgent
        
        setupForAgentConversation(topicInfo: topicInfo)
        
        let agentInfo = AgentInfo(agentId: "", agentAvatar: nil)
        notifyEventListeners { listener in
            listener.chatterbox(self, willStartAgentChat: agentInfo, forChat: chatId)
        }
    }
    
    internal func agentTopicStarted(withMessage message: ControlData?) {

        let agentInfo: AgentInfo
        
        if let textMessage = message as? AgentTextControlMessage {
            agentInfo = AgentInfo(agentId: textMessage.data.sender?.name ?? "", agentAvatar: textMessage.data.sender?.avatarPath)
        } else {
            agentInfo = AgentInfo(agentId: "", agentAvatar: nil)
        }
        
        notifyEventListeners { listener in
            listener.chatterbox(self, didStartAgentChat: agentInfo, forChat: chatId)
        }
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
        notifyEventListeners { listener in
            listener.chatterbox(self, didFinishAgentChat: agentInfo, forChat: chatId)
        }
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
    
    private func showLiveAgentUnavailableMessage() {
        if let email = session?.settings?.brandingSettings?.supportEmail,
            let phone = session?.settings?.brandingSettings?.supportPhone,
            let conversationId = conversationContext.conversationId,
            let sessionId = conversationContext.sessionId {
        
            let taskId = conversationContext.taskId
            let message = NSLocalizedString("I'm sorry, no agents are currently available. Please call us at \(phone), email us at \(email), or try again later.",
                comment: "Message when no agents available during live agent transfer")
            let textControl = OutputTextControlMessage(withValue: message, sessionId: sessionId, conversationId: conversationId, taskId: taskId, direction: MessageDirection.fromServer)
            notifyDataListeners { listener in
                listener.chatterbox(self, didReceiveControlMessage: textControl, forChat: chatId)
            }
        }
    }
}
