//
//  MultiSelectControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/18/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct MultiSelectControlMessage: Codable, ControlData {

    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.multiSelect
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    let type: String = "consumerTextMessage"
    var data: RichControlData<ControlWrapper<[String]?, PickerMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<[String]?, PickerMetadata>>) {
        data = withData
    }
    
    init(withValue value: [String], fromMessage message: MultiSelectControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
}
