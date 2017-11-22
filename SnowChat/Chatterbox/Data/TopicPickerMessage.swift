//
//  TopicPickerMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation


struct TopicPickerMessage: Codable, CBChannelEventData {
    var eventType: CBChannelEvent = .topicPicker
    
    let type: String
    let data: RichControlData<ControlWrapper>
    
    struct ControlWrapper: Codable {
        let uiType: String = "TopicPicker"
        let model: SystemTextMessage.ModelType
        let value: String
    }
    
    init(forSession sessionId: Int, withValue value: String) {
        type = "consumerTextMessage"
        data = RichControlData<ControlWrapper>(sessionId: 1,
                                               controlData: ControlWrapper(model: SystemTextMessage.ModelType(type: "topic"), value: value))
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
