//
//  ChatDataListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
// Protocol for clients who wish to listen to chat data coming out of chatterbox

import Foundation

protocol ChatDataListener: NSObjectProtocol {
    
    func chatterbox(_: Chatterbox, topicStarted topic: StartedUserTopicMessage, forChat chatId: String)
    
    func chatterbox(_: Chatterbox, booleanDataReceived message: BooleanControlMessage, forChat chatId: String)
}
