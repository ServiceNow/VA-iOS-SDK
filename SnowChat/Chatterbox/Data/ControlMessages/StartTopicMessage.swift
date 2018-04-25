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
    var controlType = ChatterboxControlType.startTopic
    
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
    var data: RichControlData<StartTopicWrapper>
    
    typealias StartTopicWrapper = ControlWrapper<String?, ContextualActionMessage.ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        // nothing more to add for this one
    }
    
    init(withSessionId: String, withConversationId: String, uiMetadata: ContextualActionMessage.ContextualActionMetadata? = nil, value: ContextualActionMessage.ValueChoice = .startTopic) {
        type = "consumerTextMessage"
        let controlData: StartTopicWrapper = ControlWrapper(model: ControlModel(type: "task", name: nil),
                                                            uiType: "ContextualAction",
                                                            uiMetadata: uiMetadata,
                                                            value: value.rawValue,
                                                            content: nil)
        data = RichControlData<StartTopicWrapper>(sessionId: withSessionId, conversationId: withConversationId, direction: .fromClient, controlData: controlData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
