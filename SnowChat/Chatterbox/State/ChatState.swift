//
//  ChatTopicState.swift
//  SnowChat
//
// Manage ChatTopic states
//
//
//  Created by Marc Attinasi on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

enum ChatStates {

    case Disconnected
    case AMBInitializing
    case AMBInitialized
    case StartSystemTopic
    case UserSession
}

class ChatState: ChatEventNotification {
    
    var currentState: ChatStates
    var session: CBSession
    
    init(forSession: CBSession, initialState: ChatStates = .Disconnected) {
        currentState = initialState
        session = forSession
    }
    
    func reset() {
        // TODO: clean-up anything before resetting state...
        
        currentState = .Disconnected
    }
    
    func initializeAMB() {
        // TODO: integrate with AMB and sign the user in
    }
    
    func subscribeToChatEvents() {
        // TODO: integrate with AMB and subscribe to the session channel
    }
    
    func establishSystemTopic() {
        
        let systemTopicPicker = TopicPickerMessage(forSession: session.id, withValue: "system")
        
    }
    
    // MARK: ChatEventNotification protocol methods
    
    func onChannelInit(forChannel: CBChannel, withEventData data: InitMessage) {
        
    }
    
    func onChannelOpen(forChannel: CBChannel, withEventData data: CBChannelOpenData) {
    
    }
    
    func onChannelClose(forChannel: CBChannel, withEventData data: CBChannelCloseData) {
    
    }
    
    func onChannelRefresh(forChannel: CBChannel, withEventData data: CBChannelRefreshData) {
    
    }
}
