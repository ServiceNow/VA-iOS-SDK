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
    
    static var config: ChatBoxConfig = ChatBoxConfig(url: "http://localhost:8080") //ChatBoxConfig(url: "https://demonightlychatbot.service-now.com")
    
    struct ChatBoxConfig {
        var url: String
    }
}

struct CBUser: Codable {
    var id: String
    var token: String
    var name: String
    var consumerId: String
    var consumerAccountId: String
}

extension CBUser {
    init(clone src: CBUser) {
        self.id = src.id
        self.token = src.token
        self.name = src.name
        self.consumerId = src.consumerId
        self.consumerAccountId = src.consumerAccountId
    }
}

struct CBVendor: Codable {
    var name: String
    var vendorId: String
    var consumerId: String
    var consumerAccountId: String
}

extension CBVendor {
    init(clone src: CBVendor) {
        self.name = src.name
        self.vendorId = src.vendorId
        self.consumerId = src.consumerId
        self.consumerAccountId = src.consumerAccountId
    }
}

func getDeviceIdentifier() -> String {
    return "1234"
}

struct CBSession: Codable {
    var id: String
    var user: CBUser
    var vendor: CBVendor
    var sessionState: SessionState = .closed
    var welcomeMessage: String?
    var deviceId: String { return getDeviceIdentifier() }

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

extension CBSession {
    init(clone src: CBSession) {
        self.id = src.id
        self.user = CBUser(clone: src.user)
        self.vendor = CBVendor(clone: src.vendor)
        self.sessionState = src.sessionState
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
    // TODO: serialization methods?
}

// MARK: - Channel events

protocol CBChannelEventData: CBStorable, Codable {
    var eventType: CBChannelEvent { get }
}

struct CBChannelEventUnknownData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelEventUnknown
}

struct CBChannelOpenData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelOpen
}

struct CBChannelCloseData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelClose
}

struct CBChannelRefreshData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelRefresh
    var status: Int
}

enum CBChannelEvent: String, Codable, CodingKey {
    case channelOpen = "openChannel"
    case channelClose = "closeChannel"
    case channelRefresh = "refreshChannel"
    
    // from Qlue protocol
    case channelInit = "Init"
    case topicPicker = "TopicPicker"
    
    case channelEventUnknown = "unknownChannelEvent"
}

// MARK: - Control Data

enum CBControlType: String, Codable {
    case controlTopicPicker = "TopicPicker"
    case controlBoolean = "Boolean"
    case controlDate = "Date"
    case controlInput = "Input"
    case contextualActionMessage = "ContextualAction"
    
    case systemMessage = "systemTextMessage"
    
    case controlTypeUnknown = "unknownControl"
}

protocol CBControlData: CBStorable, Codable {
    var id: String { get }
    var controlType: CBControlType { get }
}

struct CBControlDataUnknown: CBControlData {
    var id: String = "UNKNOWN"
    var controlType: CBControlType = .controlTypeUnknown
}

struct CBControlDataTopicPicker: CBControlData {
    var id: String
    var controlType: CBControlType
    var value: String
    
    init(withId: String, withValue: String) {
        id = withId
        controlType = .controlTopicPicker
        value = withValue
    }
}

struct CBBooleanData: CBControlData {
    var id: String
    var controlType: CBControlType
    let value: Bool
    
    init(withId: String, withValue: Bool) {
        id = withId
        controlType = .controlBoolean
        value = withValue
    }
}

struct CBDateData: CBControlData {
    var id: String
    var controlType: CBControlType
    let value: Date
    
    init(withId: String, withValue: Date) {
        id = withId
        controlType = .controlDate
        value = withValue
    }
}

struct CBInputData: CBControlData {
    var id: String
    var controlType: CBControlType
    var value: String
    
    init(withId: String, withValue: String) {
        id = withId
        controlType = .controlInput
        value = withValue
    }
}
