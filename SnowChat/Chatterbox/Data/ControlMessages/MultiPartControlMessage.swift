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
    var data: RichControlData<ControlWrapper<Int?, MultiFlowMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<Int?, MultiFlowMetadata>>) {
        data = withData
    }
    
    init(withValue value: Int, fromMessage message: MultiPartControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
}
