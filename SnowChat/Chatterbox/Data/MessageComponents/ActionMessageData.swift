//
//  ActionMessageData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ActionMessageData<T: Codable>: Codable {
    var messageId: String
    var sessionId: String
    
    var conversationId: String?
    let taskId: String?
    
    var direction: MessageDirection
    var sendTime: Date
    var receiveTime: Date?
    
    var actionMessage: T
}
