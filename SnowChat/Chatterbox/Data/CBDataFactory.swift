//
//  CBDataFactory.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class CBDataFactory {
    
    static func controlFromJSON(_ json: String) -> CBControlData {
        
        if let jsonData = json.data(using: .utf8) {
            do {
                let uiMessage = try CBData.jsonDecoder.decode(ControlMessage.self, from: jsonData)
                if let t = uiMessage.data.richControl?.uiType {
                    switch t {
                    case CBControlType.contextualActionMessage.rawValue:
                        return try CBData.jsonDecoder.decode(ContextualActionMessage.self, from: jsonData)
                    case CBControlType.topicPicker.rawValue:
                        return try CBData.jsonDecoder.decode(UserTopicPickerMessage.self, from: jsonData)
                    case CBControlType.boolean.rawValue:
                        return try CBData.jsonDecoder.decode(BooleanControlMessage.self, from: jsonData)
                    default:
                        Logger.default.logError("Unrecognized UI Control: \(t)")
                    }
                }
            } catch let parseError {
                print(parseError)
            }
        }
        return CBControlDataUnknown()
    }
    
    static func channelEventFromJSON(_ json: String) -> CBActionMessageData {
         
        if let jsonData = json.data(using: .utf8) {
            do {
                let actionMessage = try CBData.jsonDecoder.decode(ActionMessage.self, from: jsonData)
                let t = actionMessage.data.actionMessage.type
                
                switch t {
                case CBActionEventType.channelInit.rawValue:
                    return try CBData.jsonDecoder.decode(InitMessage.self, from: jsonData)
                case CBActionEventType.startUserTopic.rawValue:
                    return try CBData.jsonDecoder.decode(StartUserTopicMessage.self, from: jsonData)
                case CBActionEventType.startedUserTopic.rawValue:
                    return try CBData.jsonDecoder.decode(StartedUserTopicMessage.self, from: jsonData)
                default:
                    Logger.default.logError("Unrecognized ActionMessage type: \(t)")
                }
                
            } catch let decodeError {
                print(decodeError)
            }
        }
        
        return CBActionMessageUnknownData()
    }
}
