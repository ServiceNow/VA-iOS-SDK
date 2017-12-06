//
//  SessionAPI.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/22/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

enum SessionState {
    case NoSession
    case SessionActive
    case SessionError
}

class SessionAPI {
    
    var sessionState: SessionState = .NoSession
    var lastError: Error?
    
    var chatId: String = CBData.uuidString()
    
    func getSession(sessionInfo: CBSession, completionHandler: @escaping (CBSession?) -> Void) {
        var resultSession = sessionInfo
        
        let parameters: Parameters = ["deviceId" : sessionInfo.deviceId,
                                      "channelId": "/cs/messages/\(chatId)",
                                      "vendorId" : sessionInfo.vendor.vendorId,
                                      "consumerId": sessionInfo.user.consumerId,
                                      "consumerAccountId": sessionInfo.user.consumerAccountId,
                                      "requestTime" : Int((Date().timeIntervalSince1970 * 1000).rounded()),
                                      "direction" : "inbound",
                                      "deviceType" : "ios"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        
        Alamofire.request("\(CBData.config.url)/api/now/v1/cs/session",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: headers).responseJSON { response in
                            
            if let error = response.error {
                Logger.default.logError("Error from response: \(error)")
                
                self.sessionState = .SessionError
                self.lastError = error
                
                completionHandler(nil)
                return
            }
            
            if let value = response.result.value,
               let data = value as? NSDictionary,
               let sessionData = data.object(forKey: "session") as? NSDictionary {
                
                Logger.default.logInfo("value: \(value)")
                
                resultSession.welcomeMessage = data.object(forKey: "welcomeMessage") as? String
                resultSession.id = sessionData.object(forKey: "sessionId") as! String
                resultSession.user.consumerId = sessionData.object(forKey: "consumerId") as! String
                resultSession.user.consumerAccountId = sessionData.object(forKey: "consumerAccountId") as! String
                resultSession.sessionState = .opened
                
                self.lastError = nil
                self.sessionState = .SessionActive
                
                completionHandler(resultSession)
            } else {
                Logger.default.logError("Error getting respons data from session request: malformed server response")
                completionHandler(nil)
            }
        }
    }
    
    static func topicsFromResult(_ result: Any) -> [CBTopic] {
        guard let dictionary = result as? NSDictionary,
              let topicDictionaries = dictionary["root"] as? [NSDictionary] else { return [] }
        
        let topics: [CBTopic] = topicDictionaries.flatMap { topic in
            guard let title = topic["title"] as? String, let name = topic["topicName"] as? String else { return nil }
            return CBTopic(title: title, name: name)
        }
        
        return topics
    }
    
    func suggestTopics(searchText: String, completionHandler: @escaping([CBTopic]) -> Void) {
        let urlString = "\(CBData.config.url)/api/now/v1/cs/topics/suggest?sysparm_message=\(searchText)"
        
        Alamofire.request(urlString,
            method: .get,
            encoding: JSONEncoding.default).responseJSON { response in
                var topics = [CBTopic]()

                if response.error == nil {
                    if let result = response.result.value {
                        Logger.default.logInfo("result: \(result)")
                        
                        topics = SessionAPI.topicsFromResult(result)
                    }
                }
                completionHandler(topics)
        }
    }
    
    func allTopics(completionHandler: @escaping ([CBTopic]) -> Void) {
        Alamofire.request("\(CBData.config.url)/api/now/v1/cs/topics/tree",
            method: .get,
            encoding: JSONEncoding.default).responseJSON { response in
                var topics = [CBTopic]()
                if response.error == nil {
                    if let result = response.result.value {
                        Logger.default.logInfo("result: \(result)")
                        
                        topics = SessionAPI.topicsFromResult(result)
                    }
                }
                completionHandler(topics)
        }
    }
}
