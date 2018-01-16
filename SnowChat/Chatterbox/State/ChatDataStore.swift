//
//  ChatStateDataStore.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
// Stores all of the data needed to rehydrate a consumer's conversations.
//  - includes the consumerAccountID, used to fetch the consumer's messages from the server
//  - local copy of each message, grouped by conversation, for eventual local persistence

import Foundation

class ChatDataStore {
    private let id: String
    private var conversations = [Conversation]()
    var consumerAccountId: String?
    
    init(storeId: String) {
        id = storeId
    }
    
    // storeControlData: find or create a conversation and add a new MessageExchange with the new control data
    //
    func storeControlData(_ data: CBControlData, forConversation conversationId: String, fromChat source: Chatterbox) {
        let messageExchange = MessageExchange(withMessage: data)
        
        var index = conversations.index { $0.uniqueId() == conversationId }
        if index == nil {
            index = conversations.count
            conversations.append(Conversation(withConversationId: conversationId))
        }
        
        if let index = index {
            conversations[index].add(messageExchange)
        }
    }
    
    // storeResponseData: find the conversation and add the response to it's pending MessageExchange, completing it
    //
    func storeResponseData(_ data: CBControlData, forConversation conversationId: String) {
        let index = conversations.index { $0.uniqueId() == conversationId }
        
        if let index = index {
            conversations[index].storeResponse(data)
        }
    }
    
    // pendingMessage: get the last pendng message for a conversation, if any
    //
    func lastPendingMessage(forConversation conversationId: String) -> CBStorable? {
        return conversations.first(where: { $0.uniqueId() == conversationId })?.lastPendingMessage()
    }
    
    func conversationIds() -> [String] {
        return conversations.map({ $0.uniqueId() })
    }
    
    func conversation(forId id: String) -> Conversation? {
        return conversations.first(where: { $0.uniqueId() == id })
    }
    
    func storeConversation(_ conversation: Conversation) {
        if let index = conversations.index(where: { $0.uniqueId() == conversation.uniqueId() }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
    }
}

struct Conversation: CBStorable {
    func uniqueId() -> String {
        return id
    }
    
    private(set) var state: ConversationState
    private let id: String
    private var exchanges = [MessageExchange]()
    
    init(withConversationId conversationId: String, withState state: ConversationState = .inProgress) {
        id = conversationId
        self.state = state
    }
    
    mutating func add(_ item: MessageExchange) {
        exchanges.append(item)
    }
    
    mutating func storeResponse(_ data: CBControlData?) {
        if let last = exchanges.last, last.isComplete != true {
            let index = exchanges.count - 1
            exchanges[index].response = data
        } else {
            Logger.default.logError("Response received for conversationID \(id) with no pending message exchange!")
        }
    }
    
    func lastPendingMessage() -> CBStorable? {
        guard let last = exchanges.last, !last.isComplete else { return nil }
    
        return last.message
    }
    
    func messageExchanges() -> [MessageExchange] {
        return exchanges
    }
    
    enum ConversationState {
        case inProgress
        case completed
        case unknown
    }
}

struct MessageExchange {
    var isComplete: Bool {
        // Exchange is complete if there is a response, or if the message type needs no response
        if !needsResponse() {
            return true
        } else {
            return response != nil
        }
    }
    
    var message: CBStorable
    var response: CBStorable?
    
    init(withMessage message: CBStorable) {
        self.message = message
    }
    
    private func needsResponse() -> Bool {
        return !(message is OutputTextMessage)
    }
}
