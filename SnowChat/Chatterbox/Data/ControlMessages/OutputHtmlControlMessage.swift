//
//  OutputHtmlControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct OutputHtmlControlMessage: Codable, ControlData {
    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.outputHtml
    
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
    var data: RichControlData<ControlWrapper<String, UIMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String, UIMetadata>>) {
        data = withData
    }
}
