//
//  Chatterbox+History.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// MARK: - Chatterbox History, Synchronization, and Persistence Methods

extension Chatterbox {
    
    // MARK: - Sync Current Conversation
    
    func syncConversation(_ completion: @escaping (Int) -> Void) {
        // get the newest message and see if there are any messages newer than that for this consumer

        guard let consumerAccountId = session?.user.consumerAccountId else {
            logger.logError("No consumerAccountId in syncConversation!")
            return
        }
        guard let conversationId = conversationContext.conversationId,
            let conversation = chatStore.conversation(forId: conversationId),
            let newestServerMessage = conversation.newestServerMessage() else {
                logger.logError("Could not determine last message ID")
                completion(0)
                return
        }
        
        apiManager.fetchNewerConversations(forConsumer: consumerAccountId, afterMessage: newestServerMessage.messageId, completionHandler: { [weak self] conversations in
            guard let strongSelf = self else { return }
            
            if conversations.count == 0 {
                strongSelf.logger.logDebug("Sync with NO conversation returned - nothing to do!")
                completion(0)
            } else {
                // changes on the server - reload from saved state
                strongSelf.loadDataFromPersistence { (error) in
                    let count = strongSelf.chatStore.conversations.count
                    completion(count)
                }
            }
        })
    }
    
    fileprivate func syncConversationState(_ conversation: Conversation) {
        let conversationId = conversation.conversationId
        
        switch conversation.state {
        case .inProgress:
            logger.logInfo("Conversation \(conversationId) is in progress")
            let topicInfo = TopicInfo(topicId: nil, topicName: nil, taskId: nil, conversationId: conversationId)
            resumeUserTopic(topicInfo: topicInfo)
        case .chatProgress:
            logger.logInfo("Live Agent session \(conversationId) is in progress")
            resumeLiveAgentTopic(conversation: conversation)
        case .completed, .error, .canceled:
            logger.logInfo("No conversation in progress - finish the topic to mark it as completed")
            finishTopic(conversationId)
        case .unknown:
            logger.logError("Unknown conversation state in syncConversation!")
        }
    }
    
    internal func flattenMessageExchanges(_ exchanges: [MessageExchange]) -> [ControlData] {
        var messages = [ControlData]()
        
        exchanges.forEach({ exchange in
            messages.append(exchange.message)
            if let response = exchange.response {
                messages.append(response)
            }
        })
        
        return messages
    }
    
    internal func addExchanges(_ messageExchanges: [MessageExchange], newerThan subjectExchange: MessageExchange?, forConversation conversationId: String) {
        var newerExchanges: [MessageExchange]
        
        if let subjectExchange = subjectExchange {
            newerExchanges = messageExchanges.filter { exchange -> Bool in
                return exchange.message.messageTime.timeIntervalSince(subjectExchange.message.messageTime) > 0
            }
        } else {
            // nothing to compare to, so use them all
            newerExchanges = messageExchanges
        }
        
        guard newerExchanges.count > 0 else {
            logger.logDebug("no messages newer than what we have: already in sync")
            return
        }
        
        newerExchanges.forEach { exchange in
            self.storeHistoryAndPublish(exchange, forConversation: conversationId)
        }
    }
}

extension Chatterbox {
    
    // MARK: Fetch older messages as user needs them (user scrolled up)
    
    func fetchOlderMessages(_ completion: @escaping (Int) -> Void) {
        // request another page of messages prior to the first message we have
        guard let oldestMessage = chatStore.oldestMessage(),
            let consumerAccountId = session?.user.consumerAccountId  else {
                logger.logError("No oldest message or consumerAccountId in fetchOlderMessages")
                completion(0)
                return
        }

        notifyDataListeners { listener in
            listener.chatterbox(self, willLoadConversationsForConsumerAccount: consumerAccountId, forChat: chatId)
        }
        
        apiManager.fetchOlderConversations(forConsumer: consumerAccountId, beforeMessage: oldestMessage.messageId, completionHandler: { [weak self] conversations in
            guard let strongSelf = self else {
                completion(0)
                return
            }
            
            var count = 0
            
            let reversedConversations = conversations.reversed()
            
            if let lastConversation = reversedConversations.last {
                
                reversedConversations.forEach { [weak self] conversation in
                    guard let strongSelf = self else { return }
                    
                    guard !conversation.isForSystemTopic() else {
                        strongSelf.logger.logError("Unexpected SystemTopic conversation in fetchOlderMessages!!! skipping...")
                        return
                    }
                    
                    var conversation = conversation

                    strongSelf.chatStore.findOrCreateConversation(conversation.conversationId, withName: conversation.topicTypeName, withState: conversation.state, isPartial: conversation.isPartial)
                    
                    if conversation.conversationId != lastConversation.conversationId {
                        conversation = strongSelf.completeConversationIfNeeded(conversation)
                    }

                    count += strongSelf.loadConversationHistory(conversation)
                }
            }
            
            strongSelf.notifyDataListeners { listener in
                listener.chatterbox(strongSelf, didLoadConversationsForConsumerAccount: consumerAccountId, forChat: strongSelf.chatId)
            }
            
            completion(count)
        })
    }
    
    func loadConversationHistory(_ conversation: Conversation) -> Int {
        var count = 0
        let conversationId = conversation.conversationId
        
        notifyDataListeners { listener in
            listener.chatterbox(self, willLoadConversationHistory: conversationId, forChat: chatId)
        }
        
        let reversedMessages = conversation.messageExchanges().reversed()
        if let lastExchange = reversedMessages.last {
            
            reversedMessages.forEach { exchange in
                
                var shouldStore: Bool
                if conversation.isPartial && exchange.message.messageId == lastExchange.message.messageId {
                    // if this is the last exchange, and the conversation is partially loaded,
                    // make sure it is complete before we store it
                    shouldStore = exchange.isComplete
                } else {
                    shouldStore = true
                }
                
                if shouldStore {
                    self.storeHistoryAndPublish(exchange, forConversation: conversationId)
                    count += (exchange.response != nil ? 2 : 1)
                } else {
                    logger.logDebug("Skipping history load of incomplete exchange: \(exchange)")
                }
            }
        }
        
        notifyDataListeners { listener in
           listener.chatterbox(self, didLoadConversationHistory: conversationId, forChat: chatId)
        }
        
        return count
    }

    fileprivate func completeConversationIfNeeded( _ conversation: Conversation) -> Conversation {
        // if the conversation are marked as partial it is because we are completing a previous partial conversation
        // so we will update it to `complete` (non-partial)
        var updatedConversation = conversation
        let conversationId = conversation.conversationId
        
        if let existingConversation = self.conversation(forId: conversationId),
            existingConversation.isPartial {
            logger.logDebug("Completing partial conversation: \(existingConversation.topicTypeName)")
            
            chatStore.completeConversation(conversationId)
            updatedConversation.isPartial = false
        }
        return updatedConversation
    }
}

extension Chatterbox {
    
    // MARK: - Persistence Methods: load from service
    
    internal func saveDataToPersistence() {
        do {
            try chatStore.save()
        } catch let error {
            logger.logError("Exception storing chatStore: \(error)")
        }
    }
    
    internal func loadDataFromPersistence(completionHandler: @escaping (Error?) -> Void) {
        // clear the local database and reload from service
        chatStore.reset()
        refreshConversations(skipSyncingState: false, completionHandler: completionHandler)
    }
    
    // refreshConversations - pull all conversations from the service for the current consumerAccountId
    // for each retrieved conversation, store it and notify listener of new conversations to display
    // The state of the conversation is very specific: only the LAST conversation can be 'inProgress'.
    // All others are marked as 'completed' regardless of the server's notion of the state
    //
    // If the last conversation is in-progress, we have to process it like a live conversation, not
    // one loaded from history, to ensure that the controls are displayed as they need to be for an
    // active convresation.
    //
    // Unless we are skipping synchronization of conversation state we also have to resume the conversation by sending the showTopic message
    // to ensure that the server knows it was resumed by our current session
    internal func refreshConversations(skipSyncingState: Bool = false, completionHandler: @escaping (Error?) -> Void) {
        
        if let consumerId = session?.user.consumerAccountId {
            logger.logDebug("--> Loading conversations for \(consumerId)")
            
            notifyDataListeners { listener in
                listener.chatterbox(self, willLoadConversationsForConsumerAccount: consumerId, forChat: self.chatId)
            }
            
            apiManager.fetchConversations(forConsumer: consumerId, completionHandler: { [weak self] conversations in
                guard let strongSelf = self else { return }
                
                guard let lastConversation = conversations.last else {
                    // no messages - signal we are finished
                    strongSelf.notifyDataListeners { listener in
                        listener.chatterbox(strongSelf, didLoadConversationsForConsumerAccount: consumerId, forChat: strongSelf.chatId)
                    }
                    completionHandler(nil)
                    return
                }
                
                conversations.forEach { conversation in
                    guard !conversation.isForSystemTopic() else {
                        strongSelf.logger.logError("Unexpected SystemTopic conversation in refreshConversation!!!")
                        return
                    }
                    
                    var conversation = conversation
                    let isLastConversation = conversation.conversationId == lastConversation.conversationId
                    let isInProgress = isLastConversation && conversation.state.isInProgress && strongSelf.canResumeConversation(conversation)
                    
                    if !isInProgress {
                        // normalize the completion state (error, canceled, completed all become completed)
                        conversation.state = .completed
                    }
                    
                    if conversation.isPartial {
                        strongSelf.logger.logDebug("conversation is incomplete: \(conversation.topicTypeName)")
                    }
                    
                    strongSelf.storeConversationAndPublish(conversation)
                    
                    if isLastConversation {
                        // notify that load is complete, unless we already did (for the in-progress conversation)
                        strongSelf.notifyDataListeners { listener in
                            listener.chatterbox(strongSelf, didLoadConversationsForConsumerAccount: consumerId, forChat: strongSelf.chatId)
                        }
                        
                        if !skipSyncingState {
                            strongSelf.syncConversationState(conversation)
                        }
                    }
                }
                completionHandler(nil)
            })
        } else {
            logger.logError("No consumer Account ID, cannot load data from service")
            completionHandler(ChatterboxError.invalidParameter(details: "No ConsumerAccountId set in refreshConversations"))
        }
    }
    
    internal func canResumeConversation(_ conversation: Conversation) -> Bool {
        guard let deviceType = conversation.deviceType else { return false }
        
        // we only resume iOS-originated conversations.
        // EXCEPT live-agent conversations are always marked 'web' so we resume them regardless of deviceType
        
        let topicName = conversation.topicTypeName
        return deviceType == .iOS || topicName == "_live_agent_support_"
    }
    
    internal func storeHistoryAndPublish(_ exchange: MessageExchange, forConversation conversationId: String) {
        chatStore.storeHistory(exchange, forConversation: conversationId)
        notifyDataListeners { listener in
            listener.chatterbox(self, didReceiveHistory: exchange, forChat: chatId)
        }
    }
    
    internal func storeConversationAndPublish(_ conversation: Conversation) {

        var conversation = conversation
        
        // filter out incomplete exchanges if the conversation is partial
        if conversation.isPartial {
            if let last = conversation.messageExchanges().last, !last.isComplete {
                conversation.removeLastExchange()
            }
        }
        
        chatStore.storeConversation(conversation)
        
        notifyDataListeners { listener in
            listener.chatterbox(self, willLoadConversation: conversation.conversationId, forChat: self.chatId)
        }
        
        notifyMessagesFor(conversation)
        
        notifyDataListeners { listener in
            listener.chatterbox(self, didLoadConversation: conversation.conversationId, forChat: self.chatId)
        }
    }
    
    private func notifyMessagesFor(_ conversation: Conversation) {
        
        conversation.messageExchanges().forEach { exchange in
            let outputOnlyMessage = exchange.message.isOutputOnly || exchange.message.controlType == .multiPart
            let inProgress = conversation.state.isInProgress
            let inputPending = exchange.isComplete == false && inProgress
            
            if outputOnlyMessage || inputPending {
                notifyMessage(exchange.message)
            } else {
                notifyMessageExchange(exchange)
            }
        }
    }
    
    internal func notifyMessage(_ message: ControlData) {
        logger.logDebug("--> Notifying Message: \(message.controlType)")
        
        guard chatDataListeners.count > 0 else {
            logger.logError("No ChatDataListener in NotifyControlReceived")
            return
        }
        
        notifyDataListeners { listener in
            listener.chatterbox(self, didReceiveControlMessage: message, forChat: chatId)
        }
    }
    
    internal func notifyMessageExchange(_ exchange: MessageExchange) {
        logger.logDebug("--> Notifying MessageExchange: message=\(exchange.message.controlType) | response=\(exchange.response?.controlType ?? .unknown)")
        
        guard chatDataListeners.count > 0 else {
            logger.logError("No ChatDataListener in notifyResponseReceived")
            return
        }
        
        notifyDataListeners { listener in
            listener.chatterbox(self, didCompleteMessageExchange: exchange, forChat: chatId)
        }
    }
}
