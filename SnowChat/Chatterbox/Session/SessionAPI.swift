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
    
    var chatId: String = UUID().uuidString
    
    func getSession(sessionInfo: CBSession) -> CBSession {
        var resultSession = CBSession(clone: sessionInfo)
        
        let parameters: Parameters = ["deviceId" : sessionInfo.deviceId,
                                      "channelId": chatId,
                                      "vendorId" : sessionInfo.vendor.vendorId,
                                      "consumerId": sessionInfo.user.consumerId,
                                      "consumerAccountId": sessionInfo.user.consumerAccountId,
                                      "requestTime" : Int((Date().timeIntervalSince1970 * 1000).rounded()),
                                      "direction" : "inbound",
                                      "deviceType" : "ios"]
        let headers: HTTPHeaders = [
            "Accept": "application/json"
        ]
        
        Alamofire.request("https://snowchat.service-now.com/api/now/v1/cs/session",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: headers).responseJSON { response in
            if response.error != nil {
                // swiftlint:disable:next force_unwrapping
                Logger.default.logError("Error from response: \(response.error!)")
                return
            }
            
            if let value = response.result.value {
                Logger.default.logInfo("value: \(value)")
                
                if let data = value as? NSDictionary {
                    if let sessionData = data.object(forKey: "session") as? NSDictionary {
                        resultSession.id = sessionData.object(forKey: "sessionId") as! String
                        resultSession.user.consumerId = sessionData.object(forKey: "consumerId") as! String
                        resultSession.user.consumerAccountId = sessionData.object(forKey: "consumerAccountId") as! String
                    }
                } else {
                    Logger.default.logError("Error getting respons data from session request")
                }
                
            }
        }
        
        resultSession.sessionState = .opened
        
        return resultSession
    }
    
    func suggestTopics(searchText: String) -> [CBTopic] {
        
        return [CBTopic]()
    }
    
    func allTopics() -> [CBTopic] {
        return suggestTopics(searchText: "")
    }
}
