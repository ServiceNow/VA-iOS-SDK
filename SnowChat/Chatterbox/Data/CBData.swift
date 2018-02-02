//
//  CBData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class CBData {
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

struct CBUser: Codable {
    var id: String
    var token: String
    var username: String
    var consumerId: String
    var consumerAccountId: String
    
    var password: String?   // NOTE: will not be used once token is correctly allowed by service
}

struct CBVendor: Codable {
    var name: String
    var vendorId: String
    var consumerId: String
    var consumerAccountId: String
}

struct CBSession: Codable {
    var id: String
    var user: CBUser
    var vendor: CBVendor
    var sessionState: SessionState = .closed
    var welcomeMessage: String?
    var deviceId: String { return deviceIdentifier() }

    var extId: String { return "\(deviceId)\(vendor.consumerAccountId)" }

    var contextId: String { return "context" }
        // NOTE: unknown what this should be - reference impl had it hard-coded and commented as 'what?'

    init(id: String, user: CBUser, vendor: CBVendor) {
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

struct CBChannel: Hashable, Codable {
    let name: String
    
    var hashValue: Int {
        return name.hashValue
    }
    
    static func == (lhs: CBChannel, rhs: CBChannel) -> Bool {
        return lhs.name == rhs.name
    }
}

struct CBTopic: Codable {
    let title: String
    let name: String
}

protocol CBStorable {
    // anything storable in the DataStore must conform to this
    
    var uniqueId: String { get }
}

// MARK: - Action events

protocol CBActionMessageData: Codable {
    var eventType: CBActionEventType { get }
}

struct CBActionMessageUnknownData: CBActionMessageData {
    let eventType: CBActionEventType = .unknown
}

enum CBActionEventType: String, Codable, CodingKey {
    // from Qlue protocol
    case channelInit = "Init"
    
    case topicPicker = "TopicPicker"
    case startUserTopic = "StartTopic"
    case startedUserTopic = "StartedVendorTopic"
    case finishedUserTopic = "TopicFinished"
    
    case unknown = "unknownAction"
}

// MARK: - Control Data

enum CBControlType: String, Codable {
    case topicPicker = "TopicPicker"
    case startTopicMessage = "StartTopic"
    
    case boolean = "Boolean"
    case date = "Date"
    case input = "InputText"
    case picker = "Picker"
    case multiSelect = "Multiselect"
    case text = "OutputText"
    case outputImage = "OutputImage"
    
    case contextualAction = "ContextualAction"
    
    case unknown = "unknownControl"
}

enum MessageDirection: String, Codable {
    case fromClient = "inbound"
    case fromServer = "outbound"
}

enum MessageConstants: String, Codable {
    case loginStart = "Start"
    case loginFinish = "Finish"
    case loginUserSession = "UserSession"
}

protocol CBControlData: CBStorable, Codable {
    var id: String { get }
    
    var controlType: CBControlType { get }
    var messageId: String { get }
    var conversationId: String? { get }
    
    var direction: MessageDirection { get }
    var messageTime: Date { get }
}

struct CBControlDataUnknown: CBControlData {
    var id: String = "UNKNOWN"
    var controlType: CBControlType = .unknown
    var messageId: String = "UNKNOWN_MESSAGE_ID"
    var conversationId: String? = "UNKNOWN_CONVERSATION_ID"
    var messageTime: Date = Date()
    var direction: MessageDirection = .fromServer
    
    var uniqueId: String {
        return id
    }
}
