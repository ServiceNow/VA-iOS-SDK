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

protocol ChatEventNotification {
    func topicEvent(didReceiveStartedTopic: StartedUserTopicMessage)
    func controlEvent(didReceiveBooleanControl: BooleanControlMessage)
}
