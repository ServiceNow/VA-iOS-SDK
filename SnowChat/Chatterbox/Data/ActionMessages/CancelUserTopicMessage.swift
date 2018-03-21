//
//  StartUserSessionMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct CancelUserTopicMessage: Codable, ActionData {
    var eventType: ChatterboxActionType { return .cancelUserTopic }
    var direction: MessageDirection { return data.direction }

    var type: String
    var data: ActionMessageData<UserTopicMessageDetails>
    
    struct UserTopicMessageDetails: Codable {
        var systemActionName: String = "cancelTopic"
        var type: String = "CancelTopic"
        var conversationId: String?
        var ready: Bool?
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
