//
//  AMBClient.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol AMBListener {
    var id: String { get }
    func onMessage(_ message: String, fromChannel: String)
}

class AMBClient {
    // TODO: REPLACE WITH A REAL AMBClient
    
    var subscribers = [(channel: String, subscriber: AMBListener)]()
    
    func subscribe(forChannel channel: String, receiver: AMBListener) {
        let subscriber = (channel: channel, subscriber: receiver)
        subscribers.append(subscriber)
    }
    
    func unsubscribe(fromChannel channel: String, receiver: AMBListener) {
        subscribers = subscribers.filter({ (subscriber) -> Bool in
            return subscriber.channel != channel && subscriber.subscriber.id != receiver.id
        })
    }
    
    // Force a publication to a channel
    func publish(onChannel channel: String, jsonMessage message: String) {
        for subscriber in subscribers {
            if (subscriber.channel == channel) {
                subscriber.subscriber.onMessage(message, fromChannel: channel)
            }
        }
    }
}
