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
    
    func chatterbox(_: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String)
    func chatterbox(_: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String)
    func chatterbox(_: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String)
    func chatterbox(_: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String)
}
