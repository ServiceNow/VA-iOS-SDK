//
//  ActionMessageData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ActionMessageData<T: Codable>: Codable {
    let taskId: String?
    
    var messageId: String
    let sessionId: String
    
    let conversationId: String?

    var direction: MessageDirection
    var sendTime: Date
    var receiveTime: Date?
    
    var actionMessage: T
}
