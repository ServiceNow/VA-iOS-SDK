//
//  MultiPartControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct MultiPartControlMessage: Codable, CBControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .multiPart
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    struct MultiFlowMetadata: Codable {
        let index: Int
        let navigationBtnLabel: String
    }
    
    let type: String = "systemTextMessage"
    var data: RichControlData<ControlWrapper<String, MultiFlowMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
        case nestedData
    }
    
    init(withData: RichControlData<ControlWrapper<String, MultiFlowMetadata>>) {
        data = withData
    }
    
    init(fromMessage message: MultiPartControlMessage) {
        data = message.data
        data.sendTime = Date()
    }
}
