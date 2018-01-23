//
//  BooleanControlMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct BooleanControlMessage: Codable, CBControlData {
    
    // MARK: - CBControlData protocol methods
    
    func uniqueId() -> String {
        return id
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .boolean
    
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
    var data: RichControlData<ControlWrapper<Bool?, UIMetadata>>
 
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<Bool?, UIMetadata>>) {
        data = withData
    }
    
    init(withValue value: Bool, fromMessage message: BooleanControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
}
