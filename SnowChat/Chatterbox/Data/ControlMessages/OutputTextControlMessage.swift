//
//  OutputTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct OutputTextControlMessage: Codable, CBControlData {
    func uniqueId() -> String {
        return id
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
    
    let type: String = "SystemTextMessage"
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
