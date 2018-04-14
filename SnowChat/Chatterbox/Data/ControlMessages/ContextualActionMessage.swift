//
//  ContextualActionMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/30/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ContextualActionMessage: Codable, ControlData {

    enum ValueChoice : String {
        case startTopic
        case showTopic
    }
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = UUID().uuidString
    var controlType = ChatterboxControlType.contextualAction

    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    var options: [LabeledValue] {
        if let inputControls = data.richControl?.uiMetadata?.inputControls, let index = inputControls.index(where: { inputControl in
            inputControl.uiType == "Picker"
        }) {
            if let options = inputControls[index].uiMetadata?.options {
                return options
            }
        }
        return []
    }
    
    var type: String
    var data: RichControlData<ContextualActionWrapper>

    typealias ContextualActionWrapper = ControlWrapper<String?, ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        let inputControls: [ControlWrapper<String?, ContextualControlMetadata>]?
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
