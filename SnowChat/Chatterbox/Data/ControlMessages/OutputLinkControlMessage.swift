//
//  OutputLinkControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct OutputLinkControlMessage: Codable, ControlData {
    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.outputLink
    
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
    
    var isOutputOnly: Bool {
        return true
    }

    let type: String = "systemTextMessage"
    var data: RichControlData<ControlWrapper<OutputLinkValue, UIMetadata>>
    
    struct OutputLinkValue: Codable {
        var action: String
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<OutputLinkValue, UIMetadata>>) {
        data = withData
    }
}
