//
//  CBDataFactory.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ChatDataFactory {
    
    //swiftlint:disable:next cyclomatic_complexity function_body_length
    static func controlFromJSON(_ json: String) -> ControlData {
        
        guard let jsonData = json.data(using: .utf8) else { return ControlDataUnknown() }

        do {
            let controlMessage = try ChatUtil.jsonDecoder.decode(ControlMessageStub.self, from: jsonData)

            var controlType: ChatterboxControlType = .unknown

            // see if it is an agentText message first
            if controlMessage.data.text != nil {
                controlType = .agentText
            } else {
                // check for richControl message types
                if let uiType = controlMessage.data.richControl?.uiType {
                    controlType = ChatterboxControlType(rawValue: uiType) ?? .unknown
                }
            }
            
            switch controlType {
            case .contextualAction:
                return try ChatUtil.jsonDecoder.decode(ContextualActionMessage.self, from: jsonData)
            case.topicPicker:
                return try ChatUtil.jsonDecoder.decode(UserTopicPickerMessage.self, from: jsonData)
            case .systemError:
                return try ChatUtil.jsonDecoder.decode(SystemErrorControlMessage.self, from: jsonData)
            case .boolean:
                return try ChatUtil.jsonDecoder.decode(BooleanControlMessage.self, from: jsonData)
            case .input:
                return try ChatUtil.jsonDecoder.decode(InputControlMessage.self, from: jsonData)
            case .picker:
                return try ChatUtil.jsonDecoder.decode(PickerControlMessage.self, from: jsonData)
            case .multiSelect:
                return try ChatUtil.jsonDecoder.decode(MultiSelectControlMessage.self, from: jsonData)
            case .text:
                return try ChatUtil.jsonDecoder.decode(OutputTextControlMessage.self, from: jsonData)
            case .multiPart:
                return try ChatUtil.jsonDecoder.decode(MultiPartControlMessage.self, from: jsonData)
            case .dateTime, .time, .date:
                var dateTimeControl = try ChatUtil.jsonDecoder.decode(DateTimePickerControlMessage.self, from: jsonData)
                dateTimeControl.controlType = controlType
                return dateTimeControl
            case .outputImage:
                return try ChatUtil.jsonDecoder.decode(OutputImageControlMessage.self, from: jsonData)
            case .outputLink:
                return try ChatUtil.jsonDecoder.decode(OutputLinkControlMessage.self, from: jsonData)
            case .outputHtml:
                return try ChatUtil.jsonDecoder.decode(OutputHtmlControlMessage.self, from: jsonData)
            case .agentText:
                return try ChatUtil.jsonDecoder.decode(AgentTextControlMessage.self, from: jsonData)
            case .startTopicMessage:
                return try ChatUtil.jsonDecoder.decode(StartTopicMessage.self, from: jsonData)
            case .unknown:
                break
            }
        } catch let parseError {
            print(parseError)
        }
        return ControlDataUnknown()
    }
    
    static func actionFromJSON(_ json: String) -> ActionData {
         
        if let jsonData = json.data(using: .utf8) {
            do {
                let actionMessage = try ChatUtil.jsonDecoder.decode(ActionMessage.self, from: jsonData)
                
                guard let eventType = ChatterboxActionType(rawValue: actionMessage.data.actionMessage.type) else {
                    return ActionDataUnknown()
                }
                
                switch eventType {
                case .channelInit:
                    return try ChatUtil.jsonDecoder.decode(InitMessage.self, from: jsonData)
                case .startUserTopic:
                    return try ChatUtil.jsonDecoder.decode(StartUserTopicMessage.self, from: jsonData)
                case .startedUserTopic:
                    return try ChatUtil.jsonDecoder.decode(StartedUserTopicMessage.self, from: jsonData)
                case .finishedUserTopic:
                    return try ChatUtil.jsonDecoder.decode(TopicFinishedMessage.self, from: jsonData)
                case .topicPicker:
                    return try ChatUtil.jsonDecoder.decode(SystemTopicPickerMessage.self, from: jsonData)
                case .startAgentChat:
                    return try ChatUtil.jsonDecoder.decode(StartAgentChatMessage.self, from: jsonData)
                case .unknown:
                    return ActionDataUnknown()
                }                
            } catch let decodeError {
                print(decodeError)
            }
        }
        
        return ActionDataUnknown()
    }
    
    // MARK: - Message to JSON helper

    //swiftlint:disable:next cyclomatic_complexity
    static func jsonStringForControlMessage(_ message: ControlData) throws -> String? {
        let data: Data?
        
        switch message.controlType {
        case .boolean:
            data = try ChatUtil.jsonEncoder.encode(message as? BooleanControlMessage)
        case .input:
            data = try ChatUtil.jsonEncoder.encode(message as? InputControlMessage)
        case .picker:
            data = try ChatUtil.jsonEncoder.encode(message as? PickerControlMessage)
        case .multiSelect:
            data = try ChatUtil.jsonEncoder.encode(message as? MultiSelectControlMessage)
        case .text:
            data = try ChatUtil.jsonEncoder.encode(message as? OutputTextControlMessage)
        case .multiPart:
            data = try ChatUtil.jsonEncoder.encode(message as? MultiPartControlMessage)
        case .dateTime, .date, .time:
            data = try ChatUtil.jsonEncoder.encode(message as? DateTimePickerControlMessage)
        case .outputImage:
            data = try ChatUtil.jsonEncoder.encode(message as? OutputImageControlMessage)
        case .outputLink:
            data = try ChatUtil.jsonEncoder.encode(message as? OutputLinkControlMessage)
        case .outputHtml:
            data = try ChatUtil.jsonEncoder.encode(message as? OutputHtmlControlMessage)
        case .agentText:
            data = try ChatUtil.jsonEncoder.encode(message as? AgentTextControlMessage)
            
        // seldom used control messages
        case .contextualAction:
            data = try ChatUtil.jsonEncoder.encode(message as? ContextualActionMessage)
        case .unknown:
            data = try ChatUtil.jsonEncoder.encode(message as? ControlDataUnknown)
            
        case .systemError:
            data = nil
        case .topicPicker:
            data = nil
        case .startTopicMessage:
            data = nil
        }
        
        if let data = data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}

// ControlMessageStub is used to decode just the basic ControlMessage fields, which can then be queried
// to determine the actual type to decode
//
private struct ControlMessageStub: Codable {
    let type: String
    let data: ControlStub
    
    struct ControlStub: Codable {
        let richControl: UIType?
        let text: String?
    }
    
    struct UIType: Codable {
        let uiType: String
    }
}
