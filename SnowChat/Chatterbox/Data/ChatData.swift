//
//  ChatData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ChatUser: Codable {
    var consumerId: String
    var consumerAccountId: String
}

struct ChatVendor: Codable {
    var name: String
    var vendorId: String
}

struct ChatSessionContext {
    var deviceId: String { return "1234" } //{ return deviceIdentifier() }
    var vendor: ChatVendor
}

struct ChatSession: Codable {
    var id: String
    var user: ChatUser
    var sessionState: SessionState = .closed
    var welcomeMessage: String?

    var contextId: String { return "context" }
        // NOTE: unknown what this should be - reference impl had it hard-coded and commented as 'what?'

    init(id: String, user: ChatUser) {
        self.id = id
        self.user = user
        self.sessionState = .closed
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case id
        case user
        case welcomeMessage
    }
    
    enum SessionState {
        case closed
        case opened
        case error
    }
}

struct ChatTopic: Codable {
    let title: String
    let name: String
}

protocol Storable {
    // anything storable in the DataStore must conform to this
    
    var uniqueId: String { get }
}

// MARK: - Action Messages

enum ChatterboxActionType: String, Codable, CodingKey {
    // from Qlue protocol
    case channelInit = "Init"
    
    case topicPicker = "TopicPicker"
    case startUserTopic = "StartTopic"
    case cancelUserTopic = "CancelTopic"
    case startedUserTopic = "StartedVendorTopic"
    case finishedUserTopic = "TopicFinished"
    
    case startAgentChat = "StartChat"
    case supportQueueSubscribe = "SubscribeToSupportQueue"
    
    case unknown = "unknownAction"
}

protocol ActionData: Codable {
    var eventType: ChatterboxActionType { get }
}

struct ActionDataUnknown: ActionData {
    let eventType: ChatterboxActionType = .unknown
}

// MARK: - Control Data

enum ChatterboxControlType: String, Codable {
    case topicPicker = "TopicPicker"
    case startTopic = "StartTopic"
    case cancelTopic = "CancelTopic"

    case boolean = "Boolean"
    case input = "InputText"
    case picker = "Picker"
    case time = "Time"
    case date = "Date"
    case dateTime = "DateTime"
    case multiSelect = "Multiselect"
    case text = "OutputText"
    case multiPart = "MultiPartOutput"
    case outputImage = "OutputImage"
    case outputLink = "OutputLink"
    case outputHtml = "OutputHtml"
    case inputImage = "Picture"
    
    case agentText = "AgentText"
    
    case contextualAction = "ContextualAction"
    case systemError = "SystemError"
    
    case unknown = "unknownControl"
}

protocol ControlData: Storable, Codable {
    var id: String { get }
    
    var controlType: ChatterboxControlType { get }
    var messageId: String { get }
    var conversationId: String? { get }
    var taskId: String? { get }
    
    var direction: MessageDirection { get }
    var messageTime: Date { get }
    
    var isOutputOnly: Bool { get }
}

extension ControlData {
    var isOutputOnly: Bool {
        return false
    }
    
    var taskId: String? {
        return nil
    }
}

struct ControlDataUnknown: ControlData {
    
    let id: String = "UNKNOWN"
    let controlType: ChatterboxControlType = .unknown
    let messageId: String = "UNKNOWN_MESSAGE_ID"
    let conversationId: String? = "UNKNOWN_CONVERSATION_ID"
    let taskId: String? = nil
    let messageTime: Date = Date()
    let direction: MessageDirection = .fromServer
    var label: String?
    
    var uniqueId: String {
        return id
    }
    
    var isOutputOnly: Bool {
        return true
    }
    
    init(label: String? = nil) {
        self.label = label
    }
}

enum MessageDirection: String, Codable {
    case fromClient = "inbound"
    case fromServer = "outbound"
}

enum LoginStage: String, Codable {
    case loginStart = "Start"
    case loginFinish = "Finish"
    case loginUserSession = "UserSession"
}

class ChatUtil {
    static var jsonDecoder: JSONDecoder = {
        var decoder = JSONDecoder()
        
        // custom decoder: service wants milliseconds-since-1970 as an integer
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateVal = try container.decode(Int.self)
            let since1970 = TimeInterval(dateVal) / 1000
            return Date(timeIntervalSince1970: since1970)
        })
        return decoder
    }()
    
    static var jsonEncoder: JSONEncoder = {
        var encoder = JSONEncoder()
        
        // custom encoder: service sends milliseconds-since-1970 as an integer
        encoder.dateEncodingStrategy = .custom({ (date, encoder) in
            let val = Int((date.timeIntervalSince1970 * 1000).rounded())
            var encoder = encoder.singleValueContainer()
            try encoder.encode(val)
        })
        return encoder
    }()
    
    static func uuidString() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
}
