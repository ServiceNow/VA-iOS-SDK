//
//  TopicPickerMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct SystemTopicPickerMessage: Codable, ActionData {
    var eventType: ChatterboxActionType = .topicPicker
    
    var direction: MessageDirection {
        return data.direction
    }

    let type: String
    let data: RichControlData<ControlWrapper>
    
    struct ControlWrapper: Codable {
        let uiType: String = ChatterboxActionType.topicPicker.rawValue
        let model: ControlModel
        let value: String
    }
    
    init(forSession sessionId: String, withValue value: String = "system") {
        type = "consumerTextMessage"
        data = RichControlData<ControlWrapper>(sessionId: sessionId,
                                               conversationId: nil,
                                               controlData: ControlWrapper(model: ControlModel(type: "topic", name: nil), value: value))
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
