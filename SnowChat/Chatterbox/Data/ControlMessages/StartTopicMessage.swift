//
//  StartTopicMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct StartTopicMessage: Codable, CBControlData {
    func uniqueId() -> String {
        return id
    }
    
    var id: String = UUID().uuidString
    var controlType: CBControlType = .startTopicMessage
    
    let type: String
    let data: RichControlData<StartTopicWrapper>
    
    typealias StartTopicWrapper = ControlWrapper<String?, ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        // nothing more to add for this one
    }
    
    init(withSessionId: String, withConversationId: String) {
        type = "consumerTextMessage"
        let controlData: StartTopicWrapper = ControlWrapper(model: ControlModel(type: "task", name: nil), uiType: "ContextualAction", uiMetadata: nil, value: "startTopic")
        data = RichControlData<StartTopicWrapper>(sessionId: withSessionId, conversationId: withConversationId, controlData: controlData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
