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
        
        sessionManager.request("\(CBData.config.url)/api/now/v1/cs/session",
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
    
    func retrieve(conversation conversationId: String, completionHandler: @escaping ([CBControlData]) -> Void) {
        sessionManager.request("\(CBData.config.url)/api/now/v1/cs/conversation/\(conversationId)/message",
            method: .get,
            encoding: JSONEncoding.default).validate().responseJSON { response in
                var messages = [CBControlData]()
                if response.error == nil {
                    if let result = response.result.value {
                        messages = APIManager.messagesFromResult(result)
                    }
                }
                completionHandler(messages)
        }
    }
    
    // MARK: - Response Parsing
    
    private static func messagesFromResult(_ result: Any) -> [CBControlData] {
        guard let dictionary = result as? NSDictionary,
            let messageArray = dictionary["conversation"] as? [NSDictionary] else { return [] }
        
        let messages: [CBControlData] = messageArray.flatMap { message in
            if let richControl = message["richControl"] as? NSDictionary, let uiType = richControl["uiType"] as? String, let controlType = CBControlType(rawValue: uiType) {
                switch controlType {
                default:
                    Logger.default.logError("Unrecognized message type in messageFromResult: \(controlType) - \(richControl)")
                }
            }
            return nil
        }
        return messages
    }
    
}
