//
//  CBDataFactory.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class CBDataFactory {
    
    //swiftlint:disable:next cyclomatic_complexity
    static func controlFromJSON(_ json: String) -> CBControlData {
        
        if let jsonData = json.data(using: .utf8) {
            do {
                let uiMessage = try CBData.jsonDecoder.decode(ControlMessageStub.self, from: jsonData)
                
                guard let controlType = CBControlType(rawValue: uiMessage.data.richControl.uiType) else {
                    return CBControlDataUnknown()
                }
                
                switch controlType {
                case .contextualAction:
                    return try CBData.jsonDecoder.decode(ContextualActionMessage.self, from: jsonData)
                case.topicPicker:
                    return try CBData.jsonDecoder.decode(UserTopicPickerMessage.self, from: jsonData)
                case .boolean:
                    return try CBData.jsonDecoder.decode(BooleanControlMessage.self, from: jsonData)
                case .input:
                    return try CBData.jsonDecoder.decode(InputControlMessage.self, from: jsonData)
                case .picker:
                    return try CBData.jsonDecoder.decode(PickerControlMessage.self, from: jsonData)
                case .multiSelect:
                    return try CBData.jsonDecoder.decode(MultiSelectControlMessage.self, from: jsonData)
                case .text:
                    return try CBData.jsonDecoder.decode(OutputTextControlMessage.self, from: jsonData)
                case .multiPart:
                    return try CBData.jsonDecoder.decode(MultiPartControlMessage.self, from: jsonData)
                case .outputImage:
                    return try CBData.jsonDecoder.decode(OutputImageControlMessage.self, from: jsonData)
                default:
                    Logger.default.logError("Unrecognized UI Control: \(controlType)")
                }
            } catch let parseError {
                print(parseError)
            }
        }
        return CBControlDataUnknown()
    }
    
    static func actionFromJSON(_ json: String) -> CBActionMessageData {
         
        if let jsonData = json.data(using: .utf8) {
            do {
                let actionMessage = try CBData.jsonDecoder.decode(ActionMessage.self, from: jsonData)
                
                guard let eventType = CBActionEventType(rawValue: actionMessage.data.actionMessage.type) else {
                    return CBActionMessageUnknownData()
                }
                
                switch eventType {
                case .channelInit:
                    return try CBData.jsonDecoder.decode(InitMessage.self, from: jsonData)
                case .startUserTopic:
                    return try CBData.jsonDecoder.decode(StartUserTopicMessage.self, from: jsonData)
                case .startedUserTopic:
                    return try CBData.jsonDecoder.decode(StartedUserTopicMessage.self, from: jsonData)
                case .finishedUserTopic:
                    return try CBData.jsonDecoder.decode(TopicFinishedMessage.self, from: jsonData)
                default:
                    Logger.default.logError("Unrecognized ActionMessage type: \(eventType)")
                }
                
            } catch let decodeError {
                print(decodeError)
            }
        }
        
        return CBActionMessageUnknownData()
    }
    
    // MARK: - Message to JSON helper
    
    static func jsonStringForControlMessage(_ message: CBControlData) throws -> String? {
        let data: Data?
        
        switch message.controlType {
        case .boolean:
            data = try CBData.jsonEncoder.encode(message as? BooleanControlMessage)
        case .input:
            data = try CBData.jsonEncoder.encode(message as? InputControlMessage)
        case .picker:
            data = try CBData.jsonEncoder.encode(message as? PickerControlMessage)
        case .multiSelect:
            data = try CBData.jsonEncoder.encode(message as? MultiSelectControlMessage)
        case .text:
            data = try CBData.jsonEncoder.encode(message as? OutputTextControlMessage)
        case .multiPart:
            data = try CBData.jsonEncoder.encode(message as? MultiPartControlMessage)
        case .outputImage:
            data = try CBData.jsonEncoder.encode(message as? OutputImageControlMessage)
        default:
            data = nil
            Logger.default.logError("Unrecognized control type: \(message.controlType)")
        }
        
        if let data = data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
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
