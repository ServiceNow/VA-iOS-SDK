//
//  DateOrTimePickerControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/20/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct DateOrTimePickerControlMessage: ControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.time
    
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
    
    let type: String = "consumerTextMessage"
    var data: RichControlData<ControlWrapper<String?, UIMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String?, UIMetadata>>) {
        data = withData
    }
    
    init(withValue value: String, fromMessage message: DateOrTimePickerControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
}
