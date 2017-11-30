//
//  SessionAPI.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/22/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

class SessionAPI {
    
    var chatId: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    
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
                
                completionHandler(nil)
                return
            }
            
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
    
    func suggestTopics(searchText: String, completionHandler: ([CBTopic]) -> Void) {
        completionHandler([CBTopic]())
    }
    
    func allTopics(completionHandler: ([CBTopic]) -> Void) {
        suggestTopics(searchText: "", completionHandler: completionHandler)
    }
}
