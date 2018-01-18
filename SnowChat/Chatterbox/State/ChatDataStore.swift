//
//  ChatStateDataStore.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
// Stores all of the data needed to rehydrate a consumer's conversations.
//  - local copy of each message, grouped by conversation, for local persistence

import Foundation

class ChatDataStore {
    private let id: String
    internal var conversations = [Conversation]()
        
    init(storeId: String) {
        id = storeId
    }
    
    // storeControlData: find or create a conversation and add a new MessageExchange with the new control data
    //
    func storeControlData(_ data: CBControlData, forConversation conversationId: String, fromChat source: Chatterbox) {
        let index = findOrCreateConversation(conversationId)
        conversations[index].add(MessageExchange(withMessage: data))
    }
    
    // storeResponseData: find the conversation and add the response to it's pending MessageExchange, completing it
    //
    func storeResponseData(_ data: CBControlData, forConversation conversationId: String) {
        let index = conversations.index { $0.uniqueId() == conversationId }
        
        if let index = index {
            conversations[index].storeResponse(data)
        } else {
            Logger.default.logError("No conversation found for \(conversationId) in storeResponseData")
        }
    }
    
    internal func findOrCreateConversation(_ conversationId: String) -> Int {
        guard let foundIndex = conversations.index(where: { $0.uniqueId() == conversationId }) else {
            let index = conversations.count
            conversations.append(Conversation(withConversationId: conversationId))
            return index
        }
        return foundIndex
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

struct Conversation: CBStorable, Codable {
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
    
    mutating func storeResponse(_ data: CBControlData) {
        guard let pending = lastPendingExchange() else { fatalError("No pending message exchange in storeResponse") }
        
        let index = exchanges.count - 1
        
        // check for control type mismatch between message and response
        let message = pending.message
        guard message.controlType == data.controlType else {
            fatalError("Mismatched control types in storeResponse: message is \(message.controlType) while response is \(data.controlType)")
        }
        
        exchanges[index].response = data
    }
    
    func lastPendingMessage() -> CBStorable? {
        guard let pending = lastPendingExchange() else { return nil }
        return pending.message
    }
    
    func lastPendingExchange() -> MessageExchange? {
        guard let last = exchanges.last, !last.isComplete else { return nil }
        return last
    }
    func messageExchanges() -> [MessageExchange] {
        return exchanges
    }
    
    enum ConversationState: String, Codable {
        case inProgress = "IN PROGRESS"
        case completed = "COMPLETED"
        case unknown = "UKNONWN"
    }
}

struct MessageExchange: Codable {
    
    let message: CBControlData
    var response: CBControlData?
    
    var isComplete: Bool {
        // Exchange is complete if there is a response, or if the message type needs no response
        if !needsResponse() {
            return true
        } else {
            return response != nil
        }
    }
    
    init(withMessage message: CBControlData) {
        self.message = message
    }
    
    private func needsResponse() -> Bool {
        return !(message is OutputTextControlMessage)
    }
    
    enum CodingKeys: String, CodingKey {
        case message
        case response
    }
    
    // need custom encoder / decoder for MessageExchange because the CBControlData protocol cannot automatically be encoded or decoded
    // - our approach is to use the controlType to serialize and deserialize to and from JSON, then store and load that
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let messageString = try CBDataFactory.jsonStringForControlMessage(message) {
            try container.encode(messageString, forKey: .message)
        }
        if let response = response, let responseString = try CBDataFactory.jsonStringForControlMessage(response) {
            try container.encode(responseString, forKey: .response)
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let messageString = try values.decode(String.self, forKey: .message)
        message = CBDataFactory.controlFromJSON(messageString)
        
        do {
            let responseString = try values.decode(String.self, forKey: .response)
            response = CBDataFactory.controlFromJSON(responseString)
        } catch let error {
            Logger.default.logInfo("No response read from decoder: error=\(error.localizedDescription)")
        }
    }
}
