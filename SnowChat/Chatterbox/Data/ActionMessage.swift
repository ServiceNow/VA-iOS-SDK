//
//  ActionMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ActionMessage: Codable {
    let type: String
    let data: ActionMessageData
    
    struct ActionMessageData: Codable {
        let messageId: String
        let topicId: Int
        let taskId: Int
        let sessionId: Int
        let direction: String
        let sendTime: Date
        let receiveTime: Date
        
        let actionMessage: ActionMessageWrapper
    }
    
    struct ActionMessageWrapper: Codable {
        let type: String
    }
}
