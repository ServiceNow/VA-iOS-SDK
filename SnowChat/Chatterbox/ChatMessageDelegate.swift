//
//  ChatEventDelegate.swift
//  SnowChat
//
//  Defines the basic protocol for a delegate to implement to allow chat events to be delivered from
//  the chatterbox state management service
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol ChatMessageNotification {
    
    // MARK: Event Notifications
    
    func didReceiveStartedTopic(_ event: StartedUserTopicMessage, fromChat source: Chatterbox)
    
    // MARK: control notifications
    
    func didReceiveBooleanControl(_ data: BooleanControlMessage, fromChat source: Chatterbox)
    
    /**
    func didReceiveInputControl(_ data: InputControlMessage, fromChat source: Chatterbox)
    func didReceiveMultiSelectControl(_ data: MultiSelectControlMessage, fromChat source: Chatterbox)
    **/
}
