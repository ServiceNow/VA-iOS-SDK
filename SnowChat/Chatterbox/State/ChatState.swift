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
    case StartSystemTopic
    case UserSession
}

class ChatState : ChatEventNotification {
    
    var currentState: ChatStates
    
    init(initialState: ChatStates = .Disconnected) {
        currentState = initialState
    }
    
    func reset() {
        // TODO: clean-up anything before resetting state...
        
        currentState = .Disconnected
    }
    
    func subscribeToChatEvents() {
    }
    
    func establishSystemTopic(forUser id: String, withToken token: String) {
        
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
