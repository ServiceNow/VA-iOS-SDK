//
//  StartTopicMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct StartTopicMessage: Codable, ControlData {

    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = UUID().uuidString
    var controlType = ChatterboxControlType.startTopicMessage
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    let type: String
    let data: RichControlData<StartTopicWrapper>
    
    typealias StartTopicWrapper = ControlWrapper<String?, ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        // nothing more to add for this one
    }
    
    init(withSessionId: String, withConversationId: String) {
        type = "consumerTextMessage"
        let controlData: StartTopicWrapper = ControlWrapper(model: ControlModel(type: "task", name: nil), uiType: "ContextualAction", uiMetadata: nil, value: "startTopic", content: nil)
        data = RichControlData<StartTopicWrapper>(sessionId: withSessionId, conversationId: withConversationId, controlData: controlData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
