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
    
    var direction: MessageDirection {
        return data.direction
    }

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
        var contextData: ContextData?
    }

    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
