//
//  InitMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct InitMessage: Codable, ActionData {
    var eventType: ChatterboxActionType = .channelInit
    
    let type: String
    var data: ActionMessageData<InitMessageDetails>
    
    struct InitMessageDetails: Codable {
        let type: String
        var loginStage: LoginStage
        var systemActionName: String
        var extId: String?
        var userId: String?
        var consumerAcctId: String?
        var contextHandshake: ContextHandshake
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
        case once = "once"
        case everyMinute = "every minute"
    }
    
    // define the properties that we decode / encode (note JSON name mapping)
    private enum CodingKeys: String, CodingKey {
        case type = "updateType"
        case frequency = "updateFrequency"
    }
}

struct ContextHandshake: Codable {
    var serverContextRequest: [String: ContextItem]? = [:]
    var serverContextResponse: [String: Bool]? = [:]
    var consumerAccountId: String?
    var deviceId: String?
    var vendorId: String?

    // define the properties that we decode / encode (note JSON name mapping)
    private enum CodingKeys: String, CodingKey {
        case serverContextRequest = "serverContextReq"
        case serverContextResponse = "serverContextResp"
        case consumerAccountId = "consumerAcctId"
        case deviceId
        case vendorId
    }
}
