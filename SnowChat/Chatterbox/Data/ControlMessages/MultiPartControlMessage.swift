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
    
    var taskId: String? {
        return data.taskId
    }

    var messageTime: Date {
        return data.sendTime
    }
    
    struct MultiFlowMetadata: Codable {
        var index: Int
        let navigationBtnLabel: String
    }
    
    let type: String = "consumerTextMessage"
    var data: RichControlData<ControlWrapper<MultiPartContentValue, MultiFlowMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<MultiPartContentValue, MultiFlowMetadata>>) {
        data = withData
    }
    
    init(fromMessage message: MultiPartControlMessage) {
        data = message.data
        data.sendTime = Date()
    }
}

struct MultiPartContentValue: Codable {
    var rawValue: String?
    private var isDictionary = false
    
    private enum CodingKeys: String, CodingKey {
        case action
    }
    
    init(from decoder: Decoder) throws {
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            rawValue = stringValue
            return
        }
        
        if let actionValue = try? decoder.container(keyedBy: CodingKeys.self).decodeIfPresent(String.self, forKey: .action) {
            isDictionary = true
            rawValue = actionValue
            return
        }
    }
    
    func encode(to encoder: Encoder) throws {
        if isDictionary {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(rawValue, forKey: .action)
        } else {
            try rawValue?.encode(to: encoder)
        }
    }
}
