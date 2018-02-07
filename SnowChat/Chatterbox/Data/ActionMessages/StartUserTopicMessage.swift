//
//  StartUserSessionMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct StartUserTopicMessage: Codable, ActionData {
    var eventType: ChatterboxActionType = .startUserTopic
    
    let type: String
    var data: ActionMessageData<UserTopicMessageDetails>

    struct UserTopicMessageDetails: Codable {
        var systemActionName: String = "startVendorTopic"
        var type: String = "StartTopic"
        var taskId: String
        var topicLabel: String
        var topicName: String
        var topicId: String
        var ready: Bool
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
