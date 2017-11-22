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
    case StartUserSession
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
        currentState = .AMBInitializing

        // TODO: integrate with AMB (and sign the user in?)
        
        currentState = .AMBInitializing
    }
    
    func subscribeToChatEvents() {
        // TODO: integrate with AMB and subscribe to the session channel
    }
    
    func establishSystemTopic() {
        
        // TODO: publish TopicPicker message to AMB
        
        //let systemTopicPicker = TopicPickerMessage(forSession: session.id, withValue: "system")
        
        currentState = .StartSystemTopic
    }
    
    // MARK: ChatEventNotification protocol methods
    
    func onChannelInit(forChannel: CBChannel, withEventData data: InitMessage) {
        switch currentState {
        case .StartSystemTopic:
            // get the session from SessionManagement
            // publish InitMessage / UserSession stage
            currentState = .StartUserSession
        case .StartUserSession:
            // get the Init / finish message data and move on to user-session state
            currentState = .UserSession
        default:
            debugPrint("Unexpected state in onChannelInit: \(currentState)")
        }
    }
    
    func onChannelOpen(forChannel: CBChannel, withEventData data: CBChannelOpenData) {
    
    }
    
    func onChannelClose(forChannel: CBChannel, withEventData data: CBChannelCloseData) {
    
    }
    
    func onChannelRefresh(forChannel: CBChannel, withEventData data: CBChannelRefreshData) {
    
    }
}
