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
                let uiMessage = try CBData.jsonDecoder.decode(ControlMessageStub.self, from: jsonData)

                switch uiMessage.data.richControl.uiType {
                case CBControlType.contextualActionMessage.rawValue:
                    return try CBData.jsonDecoder.decode(ContextualActionMessage.self, from: jsonData)
                case CBControlType.topicPicker.rawValue:
                    return try CBData.jsonDecoder.decode(UserTopicPickerMessage.self, from: jsonData)
                case CBControlType.boolean.rawValue:
                    return try CBData.jsonDecoder.decode(BooleanControlMessage.self, from: jsonData)
                case CBControlType.input.rawValue:
                    return try CBData.jsonDecoder.decode(InputControlMessage.self, from: jsonData)
                case CBControlType.picker.rawValue:
                    return try CBData.jsonDecoder.decode(PickerControlMessage.self, from: jsonData)
                case CBControlType.text.rawValue:
                    return try CBData.jsonDecoder.decode(OutputTextMessage.self, from: jsonData)
                default:
                    Logger.default.logError("Unrecognized UI Control: \(uiMessage.data.richControl.uiType)")
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
                case CBActionEventType.finishedUserTopic.rawValue:
                    return try CBData.jsonDecoder.decode(TopicFinishedMessage.self, from: jsonData)
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

// ControlMessageStub is used to decode just the basic COntrolMessage fields, which can then be queried
// to determine the actual type to decode
//
private struct ControlMessageStub: Codable {
    let type: String
    let data: RichControlStub
    
    struct RichControlStub: Codable {
        let richControl: UIType
    }
    
    struct UIType: Codable {
        let uiType: String
    }
}
