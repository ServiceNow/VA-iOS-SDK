//
//  EndAgentChatMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/13/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct EndAgentChatMessage: Codable, ActionData {
    var eventType: ChatterboxActionType { return .endAgentChat }
    var direction: MessageDirection { return data.direction }

    var type: String
    var data: ActionMessageData<EndChatMessageDetails>
    
    struct EndChatMessageDetails: Codable {
        var systemActionName: String = "endChat"
        var type: String = "EndChat"
        var topicId: String
        
        init(withTopicId topicId: String) {
            self.topicId = topicId
        }
    }
    
    init(withTopicId topicId: String, systemConversationId: String, sessionId: String) {
        type = "actionMessage"
        data = ActionMessageData<EndChatMessageDetails>(messageId: ChatUtil.uuidString(),
                                                        sessionId: sessionId,
                                                        conversationId: systemConversationId,
                                                        taskId: nil,
                                                        direction: .fromClient,
                                                        sendTime: Date(), receiveTime: nil,
                                                        actionMessage: EndChatMessageDetails(withTopicId: topicId))
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
