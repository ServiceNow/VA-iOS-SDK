//
//  CBData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct CBUser {
    let id: String
    let token: String
    let name: String
    let consumerId: String
    let consummerAccountId: String
}

struct CBVendor {
    let name: String
    let vendiorId: String
    let consumerId: String
    let consummerAccountId: String
}

struct CBSession {
    let id: String
    let channel: String
    let user: CBUser
    let vendor: CBVendor
}

struct CBChannel : Hashable {
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

protocol CBChannelEventData : CBStorable {
    var eventType: CBChannelEvent { get }
    var error: Int { get }
}

struct CBChannelEventUnknownData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelEventUnknown
    let error: Int = 0
}

struct CBChannelOpenData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelOpen
    let error: Int
}

struct CBChannelCloseData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelClose
    let error: Int
}

struct CBChannelRefreshData: CBChannelEventData {
    let eventType: CBChannelEvent = .channelRefresh
    let error: Int
    
    var status: Int

}

enum CBChannelEvent: String {
    case channelOpen = "openChannel"
    case channelClose = "closeChannel"
    case channelRefresh = "refreshChannel"
    
    case channelEventUnknown = "unknownChannelEvent"
}

// MARK: - Control Data

enum CBControlType: String {
    case controlBoolean = "booleanControl"
    case controlDate = "dateControl"
    case controlInput = "inputControl"
    
    case controlTypeUnknown = "unknownControl"
}

protocol CBControlData : CBStorable {
    var id: String { get }
    var controlType: CBControlType { get }
}

struct CBControlDataUnknown: CBControlData {
    var id: String = "UNKNOWN"
    var controlType: CBControlType = .controlTypeUnknown
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
