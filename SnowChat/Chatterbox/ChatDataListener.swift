//
//  ChatDataListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
// Protocol for clients who wish to listen to chat data coming out of chatterbox

import Foundation

protocol ChatDataListener: AnyObject {
    
    // Notifies listener that a new control message was delivered from the chat service
    //
    func chatterbox(_ chatterbox: Chatterbox, didReceiveControlMessage message: CBControlData, forChat chatId: String)

    // Notifies listener that a MessageExchange was complete, meaning the user responded to a request for input
    //
    func chatterbox(_ chatterbox: Chatterbox, didCompleteMessageExchange messageExchange: MessageExchange, forChat chatId: String)

    // Notifies listener of bulk-update
    //
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversation conversationId: String, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String)
    
    // Notifies listener of loading from persistence
    //
    func chatterbox(_ chatterbox: Chatterbox, willLoadHistoryForConsumerAccount consumerAccountId: String, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didLoadHistoryForConsumerAccount consumerAccountId: String, forChat chatId: String)

    // Notifies listener of a single history exchange being loaded from the service (when loading older messages)
    func chatterbox(_ chatterbox: Chatterbox, didReceiveHistory historyExchange: MessageExchange, forChat chatId: String)
}
