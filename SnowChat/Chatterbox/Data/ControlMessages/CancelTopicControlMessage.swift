//
//  StartTopicMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct CancelTopicControlMessage: Codable, ControlData {
    
    static var value: String {
        return "cancelTopic"
    }
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = UUID().uuidString
    var controlType = ChatterboxControlType.cancelTopic
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    var isOutputOnly: Bool {
        return true
    }
    
    let type: String
    var data: RichControlData<CancelTopicWrapper>
    
    typealias CancelTopicWrapper = ControlWrapper<String?, ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        // nothing to add
    }
    
    init(withSessionId: String, withConversationId: String) {
        type = "consumerTextMessage"
        let controlData: CancelTopicWrapper = ControlWrapper(model: ControlModel(type: "task", name: nil), uiType: "ContextualAction", uiMetadata: nil, value: CancelTopicControlMessage.value, content: nil)
        data = RichControlData<CancelTopicWrapper>(sessionId: withSessionId, conversationId: withConversationId, direction: .fromClient, controlData: controlData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
