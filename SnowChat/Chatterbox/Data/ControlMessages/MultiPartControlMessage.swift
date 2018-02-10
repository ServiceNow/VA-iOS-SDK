//
//  MultiPartControlMessage.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct MultiPartControlMessage: Codable, ControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.multiPart
    
    var nestedControlType: ChatterboxControlType? {
        guard let uiType = nestedControlTypeString, let controlType = ChatterboxControlType(rawValue: uiType) else { return ChatterboxControlType.unknown }
        return controlType
    }
    
    var nestedControlTypeString: String? {
        return data.richControl?.content?.uiType
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
