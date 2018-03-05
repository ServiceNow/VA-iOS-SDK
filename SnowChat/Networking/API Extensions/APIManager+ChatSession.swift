//
//  APIManager+ChatSession.swift
//  SnowChat
//
//  Created by Will Lisac on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

extension APIManager {
    
    static let defaultMessageFetchLimit = 100
    
    // MARK: - Session
    
    func startChatSession(with sessionContext: ChatSessionContext, chatId: String, completion: @escaping (Result<ChatSession>) -> Void) {
        let parameters: Parameters = [ "deviceId": sessionContext.deviceId,
                                       "deviceType": "ios",
                                       "channelId": "/cs/messages/" + chatId,
                                       "vendorId": sessionContext.vendor.vendorId]
        
        sessionManager.request(apiURLWithPath("cs/session"),
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default).validate().responseJSON { response in
                
                if let error = response.error {
                    Logger.default.logError("Error from response: \(error)")
                    completion(.failure(error))
                    return
                }
                
                if let value = response.result.value,
                    let data = value as? NSDictionary,
                    let sessionData = data.object(forKey: "session") as? NSDictionary,
                    let consumerId = sessionData.object(forKey: "consumerId") as? String,
                    let consumerAccountId = sessionData.object(forKey: "consumerAccountId") as? String,
                    let sessionId = sessionData.object(forKey: "sessionId") as? String {
                    
                    let user = ChatUser(consumerId: consumerId, consumerAccountId: consumerAccountId)
                    var chatSession = ChatSession(id: sessionId, user: user)
                    
                    chatSession.welcomeMessage = data.object(forKey: "welcomeMessage") as? String
                    chatSession.sessionState = .opened
                    
                    completion(.success(chatSession))
                } else {
                    Logger.default.logError("Error getting response data from session request: malformed server response")
                    completion(.failure(ChatterboxError.unknown(details: "malformed server response")))
                }
        }
    }
    
    func fetchConversation(_ conversationId: String, completionHandler: @escaping (Conversation?) -> Void) {
        
        sessionManager.request(apiURLWithPath("cs/conversation/\(conversationId)/message"),
            method: .get,
            encoding: URLEncoding.queryString).validate().responseJSON { response in
            
                var conversation: Conversation?
                
                if response.error == nil {
                    if let result = response.result.value as? NSDictionary,
                        let conversationDictionary = result["conversation"] {
                        let conversationsArray = [conversationDictionary]
                        let conversations = APIManager.conversationsFromResult(conversationsArray)
                        conversation = conversations.first
                    }
                }
                completionHandler(conversation)
        }
    }
    
    func fetchConversations(forConsumer consumerId: String, completionHandler: @escaping ([Conversation]) -> Void) {
        fetchConversationsInternal(forConsumer: consumerId, completionHandler: completionHandler)
    }
    
    func fetchNewerConversations(forConsumer consumerId: String, afterMessage messageId: String, completionHandler: @escaping ([Conversation]) -> Void) {
        fetchConversationsInternal(forConsumer: consumerId, relativeTo: messageId, before: false, completionHandler: completionHandler)
    }

    func fetchOlderConversations(forConsumer consumerId: String, beforeMessage messageId: String, completionHandler: @escaping ([Conversation]) -> Void) {
        fetchConversationsInternal(forConsumer: consumerId, relativeTo: messageId, before: true, completionHandler: completionHandler)
    }

    private func fetchConversationsInternal(forConsumer consumerId: String,
                                            relativeTo messageId: String? = nil,
                                            before: Bool = true,
                                            limit: Int = APIManager.defaultMessageFetchLimit,
                                            completionHandler: @escaping ([Conversation]) -> Void) {
        var parameters: Parameters = ["sysparm_limit": limit,
                                      "sysparm_sort": "desc"]
        if messageId != nil {
            parameters["lastMessageId"] = messageId
            parameters["sysparm_sort"] = before ? "desc" : "asc"
            parameters["sysparm_age"] = before ? "older" : "newer"
        }
        
        sessionManager.request(apiURLWithPath("cs/consumerAccount/\(consumerId)/message"),
           method: .get,
           parameters: parameters,
           encoding: URLEncoding.queryString).validate().responseJSON { response in
            
            var conversations = [Conversation]()
            if response.error == nil {
                if let result = response.result.value as? NSDictionary,
                    let conversationsArray = result["conversations"] {
                    
                    conversations = APIManager.conversationsFromResult(conversationsArray)
                }
            }
            completionHandler(conversations)
        }
    }
    
    // MARK: - Response Parsing
    
    internal static func conversationsFromResult(_ result: Any, assumeMessagesReversed: Bool = true) -> [Conversation] {
        guard let conversationArray = result as? [NSDictionary] else { return [] }
        
        let conversations: [Conversation] = conversationArray.flatMap { (conversationDictionary) -> Conversation? in
            if let messagesDictionary = conversationDictionary["messages"] as? [NSDictionary],
               messagesDictionary.count > 0,
               let conversationId = conversationDictionary["topicId"] as? String {
        
                let status = conversationDictionary["status"] as? String ?? "UNKNOWN"
                let topicTypeName = conversationDictionary["topicTypeName"] as? String ?? "UNKNOWN"
                let messages = APIManager.messagesFromResult(messagesDictionary, assumeMessagesReversed: assumeMessagesReversed)
                let state = Conversation.ConversationState(rawValue: status) ?? .completed
                var conversation = Conversation(withConversationId: conversationId, withTopic: topicTypeName, withState: state)
                
                messages.forEach({ (message) in
                    if let lastPending = conversation.lastPendingMessage() as? ControlData,
                       lastPending.controlType == message.controlType {
                        conversation.storeResponse(message)
                    } else {
                        conversation.add(MessageExchange(withMessage: message))
                    }
                })
                return conversation
            } else {
                return nil
            }
        }
        return conversations
    }
    
    internal static func messagesFromResult(_ result: Any, assumeMessagesReversed: Bool = true) -> [ControlData] {
        guard let messageArray = result as? [NSDictionary] else { return [] }
        
        let messages: [ControlData] = messageArray.flatMap { message in
            // message is a dictionary, so we have to make it JSON, then convert back to ControlData
            do {
                // messages are missing the type/data wrapper, so we create one
                var wrapper = [String: Any]()
                wrapper["type"] = "systemTextMessage"
                wrapper["data"] = message
                let messageData = try JSONSerialization.data(withJSONObject: wrapper, options: JSONSerialization.WritingOptions.prettyPrinted)
                if let messageString = String(data: messageData, encoding: .utf8) {
                    let control = ChatDataFactory.controlFromJSON(messageString)
                    return control
                }
            } catch let err {
                Logger.default.logError("Error \(err) decoding message: \(message)")
            }
            return nil
        }
        return assumeMessagesReversed ? messages.reversed() : messages
    }
}
