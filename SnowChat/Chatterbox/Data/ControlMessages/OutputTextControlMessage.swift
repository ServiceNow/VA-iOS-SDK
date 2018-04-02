//
//  OutputTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct OutputTextControlMessage: Codable, ControlData {

    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var isAgent: Bool? {
        return data.isAgent
    }
    
    var sender: SenderInfo? {
        return data.sender
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.text
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var taskId: String? {
        return data.taskId
    }

    var messageTime: Date {
        return data.sendTime
    }
    
    let type: String = "systemTextMessage"
    var data: RichControlData<ControlWrapper<String, UIMetadata>>
    
    var isOutputOnly: Bool {
        return true
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withValue value: String, sessionId: String, conversationId: String, taskId: String?, direction: MessageDirection = .fromClient) {
        let wrapper = ControlWrapper<String, UIMetadata>(model: nil, uiType: "OutputText", uiMetadata: nil, value: value, content: nil)
        self.data = RichControlData<ControlWrapper<String, UIMetadata>>(sessionId: sessionId, conversationId: conversationId, direction: direction, controlData: wrapper)
        self.data.taskId = taskId
    }
    
    init(withData: RichControlData<ControlWrapper<String, UIMetadata>>) {
        data = withData
    }
}
