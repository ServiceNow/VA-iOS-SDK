//
//  ChatData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ChatUser: Codable {
    var id: String
    var token: String
    var username: String
    var consumerId: String
    var consumerAccountId: String
    
    var password: String?   // NOTE: will not be used once token is correctly allowed by service
}

struct ChatVendor: Codable {
    var name: String
    var vendorId: String
    var consumerId: String
    var consumerAccountId: String
}

struct ChatSession: Codable {
    var id: String
    var user: ChatUser
    var vendor: ChatVendor
    var sessionState: SessionState = .closed
    var welcomeMessage: String?
    var deviceId: String { return deviceIdentifier() }

    var extId: String { return "\(deviceId)\(vendor.consumerAccountId)" }

    var contextId: String { return "context" }
        // NOTE: unknown what this should be - reference impl had it hard-coded and commented as 'what?'

    init(id: String, user: ChatUser, vendor: ChatVendor) {
        self.id = id
        self.user = user
        self.vendor = vendor
        self.sessionState = .closed
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case id
        case user
        case vendor
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
    case startedUserTopic = "StartedVendorTopic"
    case finishedUserTopic = "TopicFinished"
    
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
    case startTopicMessage = "StartTopic"
    
    case boolean = "Boolean"
    case input = "InputText"
    case picker = "Picker"
    case multiSelect = "Multiselect"
    case text = "OutputText"
    case multiPart = "MultiPartOutput"
    case outputImage = "OutputImage"
    case outputLink = "OutputLink"
    
    case contextualAction = "ContextualAction"
    case systemError = "SystemError"
    
    case unknown = "unknownControl"
}

protocol ControlData: Storable, Codable {
    var id: String { get }
    
    var controlType: ChatterboxControlType { get }
    var messageId: String { get }
    var conversationId: String? { get }
    
    var direction: MessageDirection { get }
    var messageTime: Date { get }
    
    var outputOnly: Bool { get }
}

extension ControlData {
    var outputOnly: Bool {
        return false
    }
}

struct ControlDataUnknown: ControlData {
    var id: String = "UNKNOWN"
    var controlType: ChatterboxControlType = .unknown
    var messageId: String = "UNKNOWN_MESSAGE_ID"
    var conversationId: String? = "UNKNOWN_CONVERSATION_ID"
    var messageTime: Date = Date()
    var direction: MessageDirection = .fromServer
    
    var uniqueId: String {
        return id
    }
    
    var outputOnly: Bool {
        return true
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
