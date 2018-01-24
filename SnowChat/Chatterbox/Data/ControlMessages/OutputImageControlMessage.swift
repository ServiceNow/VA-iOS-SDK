//
//  OutputImageControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/24/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct OutputImageControlMessage: Codable, CBControlData {
    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .text
    
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
