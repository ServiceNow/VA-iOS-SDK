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
    
    internal func reset() {
        // I hope you mean it - replace all existing data with a new collection
        conversations = [Conversation]()
    }
    
    // storeControlData: find or create a conversation and add a new MessageExchange with the new control data
    //
    func storeControlData(_ data: ControlData, forConversation conversationId: String, fromChat source: Chatterbox) {
        let index = findOrCreateConversation(conversationId)
        conversations[index].add(MessageExchange(withMessage: data))
    }
    
    // storeResponseData: find the conversation and add the response to it's pending MessageExchange, completing it
    //
    func storeResponseData(_ data: ControlData, forConversation conversationId: String) -> MessageExchange? {
        guard let index = conversations.index(where: { $0.conversationId == conversationId }) else {
            Logger.default.logError("No conversation found for \(conversationId) in storeResponseData")
            return nil
        }
        return conversations[index].storeResponse(data)
    }
    
    func removeResponse(from exchange: MessageExchange, for conversationId: String) -> Bool {
        guard let index = conversations.index(where: { $0.conversationId == conversationId }) else {
            Logger.default.logError("No conversation found for \(conversationId) in removeResponseData")
            return false
        }
        return conversations[index].removeResponse(from: exchange)
    }
    
    internal func findOrCreateConversation(_ conversationId: String) -> Int {
        guard let foundIndex = conversations.index(where: { $0.conversationId == conversationId }) else {
            let index = conversations.count
            conversations.append(Conversation(withConversationId: conversationId))
            return index
        }
        return foundIndex
    }
    
    // pendingMessage: get the last pendng message for a conversation, if any
    //
    func lastPendingMessage(forConversation conversationId: String) -> Storable? {
        return conversations.first(where: { $0.conversationId == conversationId })?.lastPendingMessage()
    }
    
    func oldestMessage() -> ControlData? {
        var oldest: MessageExchange?
        
        conversations.forEach { conversation in
            if let conversationOldest = conversation.oldestExchange(), conversationOldest.isOlderThan(oldest) {
                oldest = conversationOldest
            }
        }
        
        guard let oldestExchange = oldest else {
            return nil
        }
        
        // message is always older than response
        return oldestExchange.message
    }
    
    func conversationIds() -> [String] {
        return conversations.map({ $0.conversationId })
    }
    
    func conversation(forId id: String) -> Conversation? {
        return conversations.first(where: { $0.conversationId == id })
    }
    
    func storeConversation(_ conversation: Conversation) {
        if let index = conversations.index(where: { $0.conversationId == conversation.conversationId }) {
            conversations[index] = conversation
            // TODO: merge existing messages if the conversation already exists ???
        } else {
            conversations.append(conversation)
        }
    }
    
    func storeHistory(_ exchange: MessageExchange, forConversation conversationId: String) {
        if let index = conversations.index(where: { $0.conversationId == conversationId }) {
            conversations[index].prepend(exchange)
        }
    }
}

struct Conversation: Storable, Codable {

    var uniqueId: String {
        return id
    }
    
    private let id: String
    private(set) var state: ConversationState
    private(set) var topicTypeName: String
    private var topicId: String
    internal var conversationId: String {
        return topicId
    }
    private var exchanges = [MessageExchange]()
    
    init(withConversationId conversationId: String, withTopic topicName: String = "UNKNOWN", withState state: ConversationState = .inProgress) {
        id = ChatUtil.uuidString()
        self.topicId = conversationId
        self.state = state
        self.topicTypeName = topicName
    }
    
    func isForSystemTopic() -> Bool {
        return topicTypeName == "system"
    }
    
    mutating func prepend(_ item: MessageExchange) {
        exchanges = [item] + exchanges
    }
    
    mutating func add(_ item: MessageExchange) {
        exchanges.append(item)
    }
    
    @discardableResult mutating func storeResponse(_ data: ControlData) -> MessageExchange? {
        guard let pending = lastPendingExchange() else { fatalError("No pending message exchange in storeResponse") }
        
        let index = exchanges.count - 1
        
        // check for control type mismatch between message and response
        let message = pending.message
        guard message.controlType == data.controlType else {
            Logger.default.logError("Mismatched control types in storeResponse: message is \(message.controlType) while response is \(data.controlType) - skipping")
            return nil
        }
        
        exchanges[index].response = data
        return exchanges[index]
    }
    
    mutating func removeResponse(from exchange: MessageExchange) -> Bool {
        if let exchangeIndex = exchanges.index(where: { ex in
            return exchange.message.messageId == ex.message.messageId
        }) {
            exchanges[exchangeIndex].response = nil
            return true
        }
        return false
    }
    
    func lastPendingMessage() -> Storable? {
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
    
    func oldestExchange() -> MessageExchange? {
        // assume the first one is the oldest
        return exchanges.first
    }
    
    func newestExchange() -> MessageExchange? {
        return exchanges.last
    }
    
    enum ConversationState: String, Codable {
        case inProgress = "IN-PROGRESS"
        case completed = "COMPLETED"
        case unknown = "UKNONWN"
    }
}

struct MessageExchange: Codable {
    
    let message: ControlData
    var response: ControlData?
    
    var isComplete: Bool {
        // Exchange is complete if there is a response, or if the message type needs no response
        if !needsResponse() {
            return true
        } else {
            return response != nil
        }
    }
    
    init(withMessage message: ControlData, withResponse response: ControlData? = nil) {
        self.message = message
        self.response = response
    }
    
    private func needsResponse() -> Bool {
        return !message.outputOnly
    }
    
    enum CodingKeys: String, CodingKey {
        case message
        case response
    }
    
    // need custom encoder / decoder for MessageExchange because the ControlData protocol cannot automatically be encoded or decoded
    // - our approach is to use the controlType to serialize and deserialize to and from JSON, then store and load that
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let messageString = try ChatDataFactory.jsonStringForControlMessage(message) {
            try container.encode(messageString, forKey: .message)
        }
        if let response = response, let responseString = try ChatDataFactory.jsonStringForControlMessage(response) {
            try container.encode(responseString, forKey: .response)
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let messageString = try values.decode(String.self, forKey: .message)
        message = ChatDataFactory.controlFromJSON(messageString)
        
        do {
            let responseString = try values.decode(String.self, forKey: .response)
            response = ChatDataFactory.controlFromJSON(responseString)
        } catch let error {
            Logger.default.logInfo("No response read from decoder: error=\(error.localizedDescription)")
        }
    }
    
    func isOlderThan(_ other: MessageExchange?) -> Bool {
        guard let other = other else {
            // we are older than nil
            return true
        }
        
        // message is always older than response
        return self.message.messageTime < other.message.messageTime
    }
}
