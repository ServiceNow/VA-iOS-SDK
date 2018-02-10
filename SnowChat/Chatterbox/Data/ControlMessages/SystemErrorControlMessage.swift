//
//  SystemErrorMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct SystemErrorControlMessage: Codable, ControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = UUID().uuidString
    var controlType = ChatterboxControlType.systemError
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    var isOutputOnly: Bool {
        return true
    }

    let type: String
    let data: RichControlData<SystemErrorWrapper>
    
    typealias SystemErrorWrapper = ControlWrapper<String?, SystemErrorMetadata>
    
    struct SystemErrorMetadata: Codable {
        let error: SystemErrorMetadataData
    }
    
    struct SystemErrorMetadataData: Codable {
        let handler: ErrorHandler
        let message: String
        let code: String
    }
    
    struct ErrorHandler: Codable {
        let type: String
        let instruction: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
