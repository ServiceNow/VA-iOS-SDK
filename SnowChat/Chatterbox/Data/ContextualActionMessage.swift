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

    let type: String
    let data: RichControlData<ContextualActionWrapper>

    typealias ContextualActionWrapper = ControlMessage.ControlWrapper<ContextualActionMetadata>
    
    struct ContextualActionMetadata: Codable {
        let inputControls: [ControlMessage.ControlWrapper<ContextualControlMetadata>]
    }
    
    struct ContextualControlMetadata: Codable {
        let options: [LabeledValue]
        let multiSelect: Bool = false
        let openByDefault: Bool = false
        
    }
    
    struct LabeledValue: Codable {
        let label: String
        let value: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
