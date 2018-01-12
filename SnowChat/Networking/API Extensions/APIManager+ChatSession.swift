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
    
    // MARK: - Session
    
    func startChatSession(with sessionInfo: CBSession, chatId: String, completion: @escaping (Result<CBSession>) -> Void) {
        var resultSession = sessionInfo
        
        let parameters: Parameters = [ "deviceId" : sessionInfo.deviceId,
                                       "channelId" : "/cs/messages/" + chatId,
                                       "vendorId" : sessionInfo.vendor.vendorId,
                                       "consumerId" : sessionInfo.user.consumerId,
                                       "consumerAccountId": sessionInfo.user.consumerAccountId,
                                       "requestTime" : Int((Date().timeIntervalSince1970 * 1000).rounded()),
                                       "direction" : "inbound",
                                       "deviceType" : "ios"]
        
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
                    let sessionData = data.object(forKey: "session") as? NSDictionary {
                    
                    resultSession.welcomeMessage = data.object(forKey: "welcomeMessage") as? String
                    resultSession.id = sessionData.object(forKey: "sessionId") as! String
                    resultSession.user.consumerId = sessionData.object(forKey: "consumerId") as! String
                    resultSession.user.consumerAccountId = sessionData.object(forKey: "consumerAccountId") as! String
                    resultSession.sessionState = .opened
                    
                    completion(.success(resultSession))
                } else {
                    Logger.default.logError("Error getting respons data from session request: malformed server response")
                    completion(.failure(ChatterboxError.unknown))
                }
        }
    }
    
    func conversation(_ conversationId: String, completionHandler: @escaping ([CBControlData]) -> Void) {
        sessionManager.request(apiURLWithPath("cs/conversation/\(conversationId)/message"),
            method: .get,
            encoding: JSONEncoding.default).validate().responseJSON { response in
                var messages = [CBControlData]()
                if response.error == nil {
                    if let result = response.result.value as? NSDictionary,
                        let conversations = result["conversations"] {
                        messages = APIManager.messagesFromResult(conversations)
                    }
                }
                completionHandler(messages)
        }
    }
    
    func conversations(forConsumer consumerId: String, completionHandler: @escaping ([Conversation]) -> Void) {
        sessionManager.request(apiURLWithPath("cs/consumerAccount/\(consumerId)/message"),
                               method: .get,
                               encoding: JSONEncoding.default).validate().responseJSON { response in
            var conversations = [Conversation]()
            if response.error == nil {
                if let result = response.result.value {
                    conversations = APIManager.conversationsFromResult(result)
                }
            }
            completionHandler(conversations)
        }
    }
    
    // MARK: - Response Parsing
    
    internal static func messagesFromResult(_ result: Any) -> [CBControlData] {
        guard let messageArray = result as? [NSDictionary] else { return [] }
        
        let messages: [CBControlData] = messageArray.flatMap { message in
            // message is a dictionary, so we have to make it JSON, then convert back to ControlData
            do {
                // messages are missing the type/data wrapper, so we create one
                var wrapper: [String: Any] = [:]
                wrapper["type"] = "systemTextMessage"
                wrapper["data"] = message
                let messageData = try JSONSerialization.data(withJSONObject: wrapper, options: JSONSerialization.WritingOptions.prettyPrinted)
                if let messageString = String(data: messageData, encoding: .utf8) {
                    let control = CBDataFactory.controlFromJSON(messageString)
                    if control.controlType != .unknown {
                        return control
                    } else {
                        Logger.default.logError("message in result is not a control - skipping: \(messageString)")
                    }
                }
            } catch let err {
                Logger.default.logError("Error \(err) decoding message: \(message)")
            }
            return nil
        }
        
        return messages
    }
    
    internal static func conversationsFromResult(_ result: Any) -> [Conversation] {
        guard let dictionary = result as? NSDictionary,
              let conversationArray = dictionary["conversations"] as? [NSDictionary] else { return [] }
        
        let conversations: [Conversation] = conversationArray.flatMap { (conversationDictionary) -> Conversation? in
            if let messagesDictionary = conversationDictionary["messages"] as? [NSDictionary],
                messagesDictionary.count > 0,
                let conversationId = messagesDictionary[0]["conversationId"] as? String {
                
                let messages = APIManager.messagesFromResult(messagesDictionary)
                let status = conversationDictionary["status"] as? String ?? "UNKNOWN"
                var conversation = Conversation(withConversationId: conversationId, withState: status == "COMPLETED" ? .completed : .inProgress)
                
                messages.forEach({ (message) in
                    if conversation.lastPendingMessage() != nil {
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
}
