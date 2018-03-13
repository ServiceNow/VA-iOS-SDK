//
//  AgentTextControl.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/21/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct AgentTextControlMessage: Codable, ControlData {
    
    var uniqueId: String {
        return id
    }
    
    // MARK: - ControlData protocol methods
    
    var direction: MessageDirection {
        return data.direction
    }
    
    var id: String = ChatUtil.uuidString()
    var controlType = ChatterboxControlType.agentText
    
    var messageId: String {
        return data.messageId
    }
    
    var conversationId: String? {
        return data.conversationId
    }
    
    var messageTime: Date {
        return data.sendTime
    }
    
    var type: String = "systemTextMessage"
    var data: AgentTextData
    var source: String?
    
    var isOutputOnly: Bool {
        return true
    }
    
    var taskId: String? {
        return data.taskId
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
        case source
    }
    
    init(withValue value: String, sessionId: String, conversationId: String, taskId: String) {
        type = "consumerTextMessage"
        let agentTextData = AgentTextData(messageId: ChatUtil.uuidString(),
                                          conversationId: conversationId,
                                          sessionId: sessionId,
                                          taskId: taskId,
                                          direction: MessageDirection.fromClient,
                                          agent: nil,
                                          isAgent: nil,
                                          sendTime: Date(),
                                          receiveTime: nil,
                                          sender: nil,
                                          text: value)
        data = agentTextData
        source = "client"
    }
}

struct AgentTextData: Codable {
    var messageId: String
    var conversationId: String
    var sessionId: String?
    var taskId: String?
    var direction: MessageDirection
    var agent: Bool?
    var isAgent: Bool?
    var sendTime: Date
    var receiveTime: Date?
    
    var sender: SenderInfo?
    var text: String
}

struct SenderInfo: Codable {
    var sysId: String?
    var name: String?
    var avatarPath: String?
}
