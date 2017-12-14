//
//  TopicFinishedMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct TopicFinishedMessage: Codable, CBActionMessageData {
    var eventType: CBActionEventType = .finishedUserTopic
    
    let type: String
    var data: ActionMessageData<TopicFinishMessageDetails>
    
    struct TopicFinishMessageDetails: Codable {
        let type: String
        var systemActionName: String
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
