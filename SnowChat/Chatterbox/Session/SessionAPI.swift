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
    
    var chatId: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    
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
            if response.error != nil {
                // swiftlint:disable:next force_unwrapping
                Logger.default.logError("Error from response: \(response.error!)")
                
                self.sessionState = .SessionError
                self.lastError = response.error
                
                completionHandler(nil)
                return
            }
            
            self.sessionState = .SessionActive

            if let value = response.result.value {
                Logger.default.logInfo("value: \(value)")
                
                if let data = value as? NSDictionary {
                    resultSession.welcomeMessage = data.object(forKey: "welcomeMessage") as? String

                    if let sessionData = data.object(forKey: "session") as? NSDictionary {
                        resultSession.id = sessionData.object(forKey: "sessionId") as! String
                        resultSession.user.consumerId = sessionData.object(forKey: "consumerId") as! String
                        resultSession.user.consumerAccountId = sessionData.object(forKey: "consumerAccountId") as! String
                        resultSession.sessionState = .opened
                        
                        self.lastError = nil
                        
                        completionHandler(resultSession)
                    }
                } else {
                    Logger.default.logError("Error getting respons data from session request")
                    completionHandler(nil)
                }
            }
        }
        
    }
    
    fileprivate func topicsFromResult(_ result: Any) -> [CBTopic] {
        var listOfTopics: [CBTopic] = []

        if let dict = result as? NSDictionary {
            let value = dict["root"]
            if value != nil {
                if let topics = value as? NSArray {
                    for topic in topics {
                        if let topic = topic as? NSDictionary {
                            Logger.default.logDebug("Topic: \(topic)")
                            if let title = topic.object(forKey: "title") as? String, let name = topic.object(forKey: "topicName") as? String {
                                listOfTopics.append(CBTopic(title: title, name: name))
                            }
                        }
                    }
                }
            }
        }
        return listOfTopics
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
                        
                        topics = self.topicsFromResult(result)
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
                        
                        topics = self.topicsFromResult(result)
                    }
                }
                completionHandler(topics)
        }
    }
}
