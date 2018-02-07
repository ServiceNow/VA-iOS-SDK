//
//  UserTopicPickerMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct UserTopicPickerMessage: Codable, ControlData {

    var uniqueId: String {
        return id
    }
    
    // MARK: - CBControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = UUID().uuidString
    
    var controlType = ChatterboxControlType.topicPicker
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    var type: String
    var data: RichControlData<ControlWrapper>
    
    struct ControlWrapper: Codable {
        let uiType: String
        var model: ControlModel
        var value: String?
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
