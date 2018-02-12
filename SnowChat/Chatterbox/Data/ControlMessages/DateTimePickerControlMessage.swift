//
//  DateTimePickerControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct DateTimePickerControlMessage: ControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.dateTime
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    let type: String = "systemTextMessage"
    var data: RichControlData<ControlWrapper<Date?, UIMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<Date?, UIMetadata>>) {
        data = withData
    }
    
    init(withValue value: Date, fromMessage message: DateTimePickerControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
}
