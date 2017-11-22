//
//  ChatMessageHandler.swift
//  SnowChat
//
//  ChatMessageHandler subscribes to AMB messages and processes them as the come in
//
//  Incoming messages from AMB are deserialized into objects and sent to
//  either the dataStore (if they are controls) or the state manager (if they are events)
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ChatMessageHandler: AMBListener {
    
    var id: String = UUID().uuidString
    
    let ambClient: AMBChatClient
    let dataStore: ChatDataStore
    let chatState: ChatState
    
    init(withAmb amb: AMBChatClient, withDataStore store: ChatDataStore, withState state: ChatState) {
        ambClient = amb
        dataStore = store
        chatState = state
    }
    
    // listen for messages on a channel
    func attach(toChannel channel: CBChannel) {
        ambClient.subscribe(forChannel: channel.name, receiver: self)
    }
    
    // stop listening to a channel (ignore all messages on that channel)
    func detach(fromChannel channel: CBChannel) {
        ambClient.unsubscribe(fromChannel: channel.name, receiver: self)
    }
    
    func publish(onChannel channel: CBChannel, jsonMessage: Data) -> Bool {
        if let jsonString = String(data: jsonMessage, encoding: .utf8) {
            ambClient.publish(onChannel: channel.name, jsonMessage: jsonString)
            return true
        }
        return false
    }
    
    func onMessage(_ message: String, fromChannel: String) {
        print("ChatMessageHandler received message on channel \(fromChannel): \(message)")
        
        if handleControlMessage(message: message, fromChannel: fromChannel) != true {
            if handleEventMessage(message: message, fromChannel: fromChannel) != true {
                print("Unhandled message: \(message)")
            }
        }
    }
 
    func handleControlMessage(message: String, fromChannel: String) -> Bool {
        var success = true
        let control = CBDataFactory.controlFromJSON(message)
        
        switch control.controlType {
        case .controlBoolean:
            if let booleanData = control as? BooleanControlMessage {
                dataStore.onBooleanControl(forChannel: CBChannel(name: fromChannel), withControlData: booleanData)
            }
        default:
            print("Unsupported control type in onMessage: \(control.controlType)")
            success = false
        }
        return success
    }
    
    func handleEventMessage(message: String, fromChannel: String) -> Bool {
        var success = true
        let event = CBDataFactory.channelEventFromJSON(message)
        
        switch event.eventType {
        case .channelInit:
            if let initEvent = event as? InitMessage {
                chatState.onChannelInit(forChannel: CBChannel(name: fromChannel), withEventData: initEvent)
            }
        default:
            success = false
        }
        
        return success
    }
}
