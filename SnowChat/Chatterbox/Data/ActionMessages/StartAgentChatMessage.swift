//
//  StartChatMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct StartAgentChatMessage: Codable, ActionData {
    var eventType: ChatterboxActionType = .startAgentChat
    
    var direction: MessageDirection {
        return data.direction
    }

    let type: String
    var data: ActionMessageData<AgentChatMessageDetails>
    
    struct AgentChatMessageDetails: Codable {
        let systemActionName: String = "startChat"
        let type: String = "StartChat"
        var topicId: String
        var taskId: String?
        var chatStage: String
        var ready: Bool?
        
        var agent: Bool?
        var isAgent: Bool?
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
