//
//  PickerControlMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct PickerControlMessage: Codable, CBControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .picker
    
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
    var data: RichControlData<ControlWrapper<String?, PickerMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String?, PickerMetadata>>) {
        data = withData
    }
    
    init(withValue value: String, fromMessage message: PickerControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
}
