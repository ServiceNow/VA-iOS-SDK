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
    func chatterbox(_ chatterbox: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String)
    
    // Notifies listener that a MessageExchange was complete, meaning the user responded to a request for input
    //
    func chattebox(_: Chatterbox, didCompleteBooleanExchange messageExchange: MessageExchange, forChat chatId: String)
    func chattebox(_: Chatterbox, didCompleteInputExchange messageExchange: MessageExchange, forChat chatId: String)
    func chattebox(_: Chatterbox, didCompletePickerExchange messageExchange: MessageExchange, forChat chatId: String)
}
