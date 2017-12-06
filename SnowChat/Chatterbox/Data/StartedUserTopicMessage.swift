//
//  StartedUserTopicMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct StartedUserTopicMessage: Codable, CBActionMessageData {
    var eventType: CBActionEventType = .startedUserTopic
    
    let type: String
    var data: ActionMessageData<UserTopicMessageDetails>
    
    struct UserTopicMessageDetails: Codable {
        let type: String
        let topicId: String
        let topicName: String
        let taskId: String
        let vendorTopicId: String
        let startStage: String
        let ready: Bool
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
