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
        //
        guard let consumerAccountId = session?.user.consumerAccountId else {
            logger.logError("No consumerAccountId in syncConversation!")
            return
        }
        guard let conversationId = conversationContext.conversationId,
            let conversation = chatStore.conversation(forId: conversationId),
            let newestExchange = conversation.newestExchange() else {
                logger.logError("Could not determine last message ID")
                completion(0)
                return
        }
        
        let newestMessage = newestExchange.message
        
        apiManager.fetchNewerConversations(forConsumer: consumerAccountId, afterMessage: newestMessage.messageId, completionHandler: { [weak self] conversationsFromService in
            guard let strongSelf = self else { return }
            
            // HACK: service is returning user and system conversations, so we remove all system topics here
            //       remove this when the service is fixed
            let conversations = strongSelf.filterSystemTopics(conversationsFromService)
            
            if conversations.count == 0 {
                strongSelf.syncNoConversationsReturned()
                completion(0)
                
            } else if conversations.count == 1 && conversations.first?.conversationId == conversationId {
                // we got back something for the current conversation; make sure it matches the response we have
                guard let receivedConversation = conversations.first else { return }
                strongSelf.syncCurrentConversation(receivedConversation, newestExchange)
                completion(1)
                
            } else {
                // if we are here we have to reload everything
                strongSelf.clearAndReloadFromPersistence(completionHandler: { (error) in
                    let count = strongSelf.chatStore.conversations.count
                    completion(count)
                })
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
        // TODO: how to resume a live agent chat session??
        case .completed, .error, .canceled:
            logger.logInfo("Conversation is no longer in progress - ending current conversations")
            finishTopic(conversationId)
        case .unknown:
            logger.logError("Unknown conversation state in syncConversation!")
        }
    }
    
    fileprivate func syncNoConversationsReturned() {
        // if no messages were returned, then we have the latest messages, just need to update the input mode
        logger.logDebug("Sync with NO conversation returned - nothing to do!")
    }
    
    fileprivate func syncCurrentConversation(_ receivedConversation: Conversation, _ newestExchange: MessageExchange) {
        guard let firstReceivedExchange = receivedConversation.messageExchanges().first,
            let receivedResponseId = firstReceivedExchange.response?.messageId,
            let ourResponseId = newestExchange.response?.messageId,
            receivedResponseId == ourResponseId  else {
                // responses do not match!
                return
        }
        
        // our last response matches the info we received, we are in sync!
        logger.logInfo("Conversation messages in sync!")
        syncConversationState(receivedConversation)
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
        
        apiManager.fetchOlderConversations(forConsumer: consumerAccountId, beforeMessage: oldestMessage.messageId, completionHandler: { [weak self] conversationsFromService in
            guard let strongSelf = self else {
                completion(0)
                return
            }
            
            var count = 0
            
            strongSelf.chatDataListener?.chatterbox(strongSelf, willLoadConversationsForConsumerAccount: consumerAccountId, forChat: strongSelf.chatId)
            
            // TODO: remove this filter when the service stops returning system messages
            let conversations = strongSelf.filterSystemTopics(conversationsFromService)
            
            conversations.forEach({ [weak self] conversation in
                guard let strongSelf = self else { return }
                
                let conversationId = conversation.conversationId
                let conversationName = conversation.topicTypeName
                _ = strongSelf.chatStore.findOrCreateConversation(conversationId, withName: conversationName, withState: conversation.state)
                
                count += strongSelf.loadConversationHistory(conversation)
            })
            
            strongSelf.chatDataListener?.chatterbox(strongSelf, didLoadConversationsForConsumerAccount: consumerAccountId, forChat: strongSelf.chatId)
            
            completion(count)
        })
    }
    
    func loadConversationHistory(_ conversation: Conversation) -> Int {
        var count = 0
        let conversationId = conversation.conversationId
        
        chatDataListener?.chatterbox(self, willLoadConversationHistory: conversationId, forChat: chatId)
        
        conversation.messageExchanges().reversed().forEach({ exchange in
            self.storeHistoryAndPublish(exchange, forConversation: conversationId)
            count += (exchange.response != nil ? 2 : 1)
        })
        
        chatDataListener?.chatterbox(self, didLoadConversationHistory: conversationId, forChat: chatId)
        
        return count
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
    
    internal func clearAndReloadFromPersistence(completionHandler: @escaping (Error?) -> Void) {
        chatStore.reset()
        loadDataFromPersistence(completionHandler: completionHandler)
    }
    
    internal func loadDataFromPersistence(completionHandler: @escaping (Error?) -> Void) {
        // TODO: load locally stored history and synchronize with the server
        //       for now we just pull from server, no local store
        /*
         do {
         let conversations = try chatStore.load()
         } catch let error {
         logger.logError("Exception loading chatStore: \(error)")
         }
         */
        
        refreshConversations(completionHandler: completionHandler)
    }
    
    internal func refreshConversations(completionHandler: @escaping (Error?) -> Void) {
        
        if let consumerId = session?.user.consumerAccountId {
            logger.logDebug("--> Loading conversations for \(consumerId)")
            
            self.chatDataListener?.chatterbox(self, willLoadConversationsForConsumerAccount: consumerId, forChat: self.chatId)
            
            apiManager.fetchConversations(forConsumer: consumerId, completionHandler: { (conversationsFromService) in
                
                // HACK: service is returning user and system conversations, so we remove all system topics here
                //       remove this when the service is fixed
                let conversations = self.filterSystemTopics(conversationsFromService)
                self.logger.logDebug(" --> loaded \(conversationsFromService.count) conversations, \(conversations.count) are for user")
                
                let lastConversation = conversations.last
                
                conversations.forEach { conversation in
                    var conversation = conversation
                    
                    let isInProgress = conversation.conversationId == lastConversation?.conversationId && conversation.state != .completed
                    if !isInProgress {
                        conversation.state = .completed
                    }
                    
                    self.storeConversationAndPublish(conversation)
                    
                    if conversation.conversationId == lastConversation?.conversationId {
                        self.syncConversationState(conversation)
                    }
                }
                
                self.chatDataListener?.chatterbox(self, didLoadConversationsForConsumerAccount: consumerId, forChat: self.chatId)
                
                completionHandler(nil)
            })
        } else {
            logger.logError("No consumer Account ID, cannot load data from service")
            completionHandler(ChatterboxError.invalidParameter(details: "No ConsumerAccountId set in refreshConversations"))
        }
    }
    
    internal func filterSystemTopics(_ conversations: [Conversation]) -> [Conversation] {
        return conversations.filter({ conversation -> Bool in
            return conversation.isForSystemTopic() == false
        })
    }
    
    internal func storeHistoryAndPublish(_ exchange: MessageExchange, forConversation conversationId: String) {
        chatStore.storeHistory(exchange, forConversation: conversationId)
        chatDataListener?.chatterbox(self, didReceiveHistory: exchange, forChat: chatId)
    }
    
    internal func storeConversationAndPublish(_ conversation: Conversation) {
        chatStore.storeConversation(conversation)
        
        self.chatDataListener?.chatterbox(self, willLoadConversation: conversation.conversationId, forChat: self.chatId)
        
        conversation.messageExchanges().forEach { exchange in
            let outputOnlyMessage = exchange.message.isOutputOnly || exchange.message.controlType == .multiPart
            let inputPending = conversation.state == .inProgress && !exchange.isComplete
            
            if outputOnlyMessage || inputPending {
                notifyMessage(exchange.message)
            } else {
                notifyMessageExchange(exchange)
            }
        }
        
        self.chatDataListener?.chatterbox(self, didLoadConversation: conversation.conversationId, forChat: self.chatId)
    }
    
    internal func notifyMessage(_ message: ControlData) {
        guard let chatDataListener = chatDataListener else {
            logger.logError("No ChatDataListener in NotifyControlReceived")
            return
        }
        
        chatDataListener.chatterbox(self, didReceiveControlMessage: message, forChat: chatId)
    }
    
    internal func notifyMessageExchange(_ exchange: MessageExchange) {
        logger.logDebug("--> Notifying MessageExchange: message=\(exchange.message.controlType) | response=\(exchange.response?.controlType ?? .unknown)")
        
        guard let chatDataListener = chatDataListener else {
            logger.logError("No ChatDataListener in notifyResponseReceived")
            return
        }
        
        chatDataListener.chatterbox(self, didCompleteMessageExchange: exchange, forChat: chatId)
    }
}
