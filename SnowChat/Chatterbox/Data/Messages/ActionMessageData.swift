//
//  ActionMessageData.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/28/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ActionMessageData<T: Codable>: Codable {
    let conversationId: String
    let taskId: String
    let messageId: String
    let sessionId: String
    
    var direction: String
    var sendTime: Date
    var receiveTime: Date?
    
    var actionMessage: T
}
