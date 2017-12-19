//
//  ChatStateDataStore.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ChatDataStore {
    
    init(storeId: String) {
        id = storeId
    }
    
    // storeControlData: find or create a conversation and add a new MessageExchange with the new control data
    //
    func storeControlData(_ data: CBControlData, expectResponse: Bool, forConversation conversationId: String, fromChat source: Chatterbox) {
        let messageExchange = MessageExchange(withMessage: data, isComplete: !expectResponse)
        
        var index = conversations.index { (conversation) -> Bool in
            return conversation.uniqueId() == conversationId
        }

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
        let index = conversations.index { (conversation) -> Bool in
            return conversation.uniqueId() == conversationId
        }
        
        if let index = index {
            conversations[index].didReceiveResponse(data)
        }
    }
    
    // pendingMessage: get the lat pendng message for a conversation, if any
    //
    func lastPendingMessage(forConversation conversationId: String) -> CBStorable? {
        let index = conversations.index { conversation in
                return conversation.uniqueId() == conversationId
            }
        
        if let index = index {
            return conversations[index].lastPendingMessage()
        }
        
        return nil
    }
    
    func conversationIds() -> [String] {
        return conversations.map({ conversation in
            return conversation.uniqueId()
        })
    }
    
    func conversation(forId id: String) -> Conversation? {
        var result: Conversation?
        
        conversations.forEach { (conversation) in
            if conversation.uniqueId() == id {
                result = conversation
            }
        }
        return result
    }
    
    private let id: String
    private var conversations = [Conversation]()
}

struct Conversation: CBStorable {
    func uniqueId() -> String {
        return id
    }
    
    private let id: String
    private let state: ConversationState
    private var exchanges = [MessageExchange]()
    
    init(withConversationId conversationId: String) {
        id = conversationId
        state = .pending
    }
    
    mutating func add(_ item: MessageExchange) {
        exchanges.append(item)
    }
    
    mutating func didReceiveResponse(_ data: CBControlData) {
        if let last = exchanges.last, last.complete != true {
            let index = exchanges.count - 1
            exchanges[index].response = data
            exchanges[index].complete = true
        } else {
            Logger.default.logError("Response received for conversationID \(id) with no pending message exchange!")
        }
    }
    
    func lastPendingMessage() -> CBStorable? {
        if let last = exchanges.last {
            if !last.complete {
                return last.message
            }
        }
        return nil
    }
    
    func messageExchanges() -> [MessageExchange] {
        return exchanges.map({ exchange in
            return exchange
        })
    }
    
    enum ConversationState {
        case pending
        case completed
        case unknown
    }
}

struct MessageExchange {
    var complete: Bool
    
    var message: CBStorable
    var response: CBStorable?
    
    init(withMessage message: CBStorable, isComplete: Bool = false) {
        self.message = message
        complete = isComplete
    }
}
