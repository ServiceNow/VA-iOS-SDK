//
//  ContextualActionMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/30/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ContextualActionMessage: Codable, CBControlData {
    func uniqueId() -> String {
        return id
    }
    
    var id: String = UUID().uuidString
    var controlType: CBControlType = .contextualActionMessage

    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    let type: String
    let data: RichControlData<ContextualActionWrapper>

    typealias ContextualActionWrapper = ControlWrapper<String?, ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        let inputControls: [ControlWrapper<String?, ContextualControlMetadata>]
    }
    
    struct ContextualControlMetadata: Codable {
        let options: [LabeledValue]
        let multiSelect: Bool = false
        let openByDefault: Bool = false
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
