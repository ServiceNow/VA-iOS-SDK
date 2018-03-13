//
//  TopicFinishedMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct TopicFinishedMessage: Codable, ActionData {
    var eventType: ChatterboxActionType = .finishedUserTopic
    
    let type: String
    var data: ActionMessageData<TopicFinishMessageDetails>
    
    struct TopicFinishMessageDetails: Codable {
        let type: String
        var systemActionName: String
    }
    
    init(withSessionId sessionId: String, withConversationId conversationId: String) {
        self.type = "actionMessage"
        self.data = ActionMessageData<TopicFinishMessageDetails>(messageId: ChatUtil.uuidString(), sessionId: sessionId, conversationId: conversationId, taskId: nil, direction: MessageDirection.fromServer, sendTime: Date(), receiveTime: Date(), actionMessage: TopicFinishedMessage.TopicFinishMessageDetails(type: "TopicFinished", systemActionName: "TopicFinished"))
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
