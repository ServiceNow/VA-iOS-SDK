//
//  ShowTopicMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct ShowTopicMessage: Codable, ActionData {
    var eventType: ChatterboxActionType { return .showTopic }
    var direction: MessageDirection { return data.direction }

    let type: String
    var data: ActionMessageData<ShowTopicMessageDetails>
    
    struct ShowTopicMessageDetails: Codable {
        var systemActionName: String = "showVendorTopic"
        var type: String = "ShowTopic"
        var topicId: String
        var ready: Bool?
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
