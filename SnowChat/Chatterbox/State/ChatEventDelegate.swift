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

    func onChannelOpen(forChannel: CBChannel, withEventData: CBChannelOpenData)
    func onChannelClose(forChannel: CBChannel, withEventData: CBChannelCloseData)
    func onChannelRefresh(forChannel: CBChannel, withEventData: CBChannelRefreshData)
    
}

protocol ChatEventControlNotification {
    
    func onBooleanControl(forChannel: CBChannel, withControlData: CBBooleanData)
    func onDateControl(forChannel: CBChannel, withControlData: CBDateData)
    func onInputControl(forChannel: CBChannel, withControlData: CBInputData)
    
}
