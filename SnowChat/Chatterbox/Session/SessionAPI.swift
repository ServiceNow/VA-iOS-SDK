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
    var chatId: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    var topics: [CBTopic]?
    
    func getSession(sessionInfo: CBSession, completionHandler: @escaping (CBSession?) -> Void) {
        var resultSession = CBSession(clone: sessionInfo)
        
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
        self.allTopics { (topics) in
            let filteredTopics = topics.filter({ (topic) -> Bool in
                return topic.name.contains(searchText)
            })
            completionHandler(filteredTopics)
        }
    }
    
    func allTopics(completionHandler: @escaping ([CBTopic]) -> Void) {
        if topics == nil {
            Alamofire.request("\(CBData.config.url)/api/now/v1/cs/topics/tree",
                method: .get,
                encoding: JSONEncoding.default).responseJSON { response in
                    
                    if response.error == nil {
                        
                        if let result = response.result.value {
                            Logger.default.logInfo("result: \(result)")
                            
                            self.topics = self.topicsFromResult(result)
                        }
                    }
                    completionHandler(self.topics ?? [CBTopic]())
            }
        }
    }
}
