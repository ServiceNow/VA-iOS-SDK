//
//  CBData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct CBUser: Codable {
    let id: String
    let token: String
    let name: String
    let consumerId: String
    let consummerAccountId: String
}

struct CBVendor: Codable {
    let name: String
    let vendiorId: String
    let consumerId: String
    let consummerAccountId: String
}

struct CBSession: Codable {
    let id: String
    let channel: String
    let user: CBUser
    let vendor: CBVendor
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
    
    case channelEventUnknown = "unknownChannelEvent"
}

// MARK: - Control Data

enum CBControlType: String {
    case controlTopicPicker = "topicPickerControl"
    case controlBoolean = "booleanControl"
    case controlDate = "dateControl"
    case controlInput = "inputControl"
    
    case controlTypeUnknown = "unknownControl"
}

protocol CBControlData: CBStorable {
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
