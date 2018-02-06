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
    
    var nestedControlType: CBControlType? {
        guard let uiType = data.richControl?.content?.uiType, let controlType = CBControlType(rawValue: uiType) else { return nil }
        return controlType
    }
    
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
        var index: Int
        let navigationBtnLabel: String
    }
    
    let type: String = "consumerTextMessage"
    var data: RichControlData<ControlWrapper<String, MultiFlowMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String, MultiFlowMetadata>>) {
        data = withData
    }
    
    init(fromMessage message: MultiPartControlMessage) {
        data = message.data
        data.sendTime = Date()
    }
}
