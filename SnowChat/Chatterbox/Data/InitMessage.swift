//
//  InitMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct InitMessage: Codable, CBChannelEventData {
    var eventType: CBChannelEvent = .channelInit
    
    let type: String
    let data: ActionMessageData
    
    struct ActionMessageData: Codable {
        let messageId: String
        let topicId: Int
        let taskId: Int
        let sessionId: Int
        let direction: String
        let sendTime: Date
        let receiveTime: Date
        let actionMessage: InitMessageDetails
    }
    
    struct InitMessageDetails: Codable {
        let type: String
        let loginStage: String
        let systemActionName: String
        let contextHandshake: ContextHandshake
    }

    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}

struct ContextItem: Codable {
    let type: ContextItemType
    let frequency: ContextItemFrequency
    
    enum ContextItemType: String, Codable, CodingKey {
        case Push = "push"
    }
    
    enum ContextItemFrequency: String, Codable, CodingKey {
        case Once = "once"
        case Minute = "every minute"
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type = "updateType"
        case frequency = "updateFrequency"
    }
}

struct ContextHandshake: Codable {
    let handshakeId: Int
    let deviceId: String
    var serverContextRequest: [String: ContextItem]
    
    init(handshakeId: Int, deviceId: String) {
        self.deviceId = deviceId
        self.handshakeId = handshakeId
        self.serverContextRequest = [:]
    }
    
    // define the properties that we decode / encode (note JSON name mapping)
    private enum CodingKeys: String, CodingKey {
        case handshakeId = "ctxHandShakeId"
        case deviceId
        case serverContextRequest = "serverContextReq"
    }
}
