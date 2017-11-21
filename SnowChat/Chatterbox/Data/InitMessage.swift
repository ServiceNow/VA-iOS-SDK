//
//  InitMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct InitMessage : Codable, CBChannelEventData {
    var eventType: CBChannelEvent = .channelInit
    
    let type: String
    let data: ActionMessageData
    
    struct ActionMessageData : Codable {
        let messageId: String
        let topicId: Int
        let taskId: Int
        let sessionId: Int
        let actionMessage: ActionMessageWrapper
    }
    
    struct ActionMessageWrapper : Codable {
        let type: String
        let loginStage: String
        let systemActionName: String
        let contextHandshake: InitContextHandshake
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}

struct InitContextItem : Codable {
    
    enum ContextItemType : String, Codable, CodingKey {
        case Push = "push"
    }
    
    enum ContextItemFrequency : String, Codable, CodingKey {
        case Once = "once"
        case Minute = "every minute"
    }
    
    let type: ContextItemType
    let frequency: ContextItemFrequency
    
    private enum CodingKeys: String, CodingKey {
        case type = "updateType"
        case frequency = "updateFrequency"
    }
}

struct InitContextHandshake : Codable {
    let handshakeId: Int
    let deviceId: String
    var serverContextRequest: [String: InitContextItem]
    
    init(handshakeId: Int, deviceId: String) {
        self.deviceId = deviceId
        self.handshakeId = handshakeId
        self.serverContextRequest = [:]
    }
    
    private enum CodingKeys: String, CodingKey {
        case handshakeId = "ctxHandShakeId"
        case deviceId
        case serverContextRequest = "serverContextReq"
    }
}

