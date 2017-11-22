//
//  AMBClient.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import AMBClient

protocol AMBListener {
    var id: String { get }
    func onMessage(_ message: String, fromChannel: String)
}

class AMBChatClient {
    var endpoint: URL
    
    private lazy var ambManager: APIManager = {
        let url = endpoint
        let instance = ServerInstance(instanceURL: url)
        let manager = APIManager(instance: instance)
        return manager
    }()
    
    var  currentState: AMBState = .signedOut
    
    enum AMBState {
        case signedOut
        case signedIn
    }
    
    init(withEndpoint url: URL) {
        endpoint = url
    }
    
    func login(userName: String, password: String, completionHandler: @escaping (Bool) -> Void) {
        ambManager.logIn(username: userName, password: password) { [weak self] success in
            if success {
                self?.currentState = .signedIn
                Logger.default.logInfo("User \(userName) logged in")
            } else {
                self?.currentState = .signedOut
                Logger.default.logError("Failed to log in")
            }
            
            completionHandler(success)
        }
    }
    
    var subscribers = [(channel: String, subscriber: AMBListener, subscription: NOWAMBSubscription)]()
    
    func subscribe(forChannel channel: String, receiver: AMBListener) {
        var subscription: NOWAMBSubscription?
        
        subscription = ambManager.ambClient.subscribe(channel) { (subscription, message) in
            guard let msg = message else {
                Logger.default.logError("Nil-message received on channel \(channel)")
                return
            }
            
            if let msgString = AMBChatClient.messageToJSON(message: msg) {
                receiver.onMessage(msgString, fromChannel: channel)
            }
        }
        
        if let subscription = subscription {
            subscribers.append((channel: channel, subscriber: receiver, subscription: subscription))
        }
    }
    
    func unsubscribe(fromChannel channel: String, receiver: AMBListener) {
        for subscriber in subscribers {
            if subscriber.channel == channel && subscriber.subscriber.id == receiver.id {
                unsubscribe(subscription: subscriber.subscription)
            }
        }
    }
    
    internal func unsubscribe(subscription subs: NOWAMBSubscription) {
        subscribers = subscribers.filter({ (subscriber) -> Bool in
            return subscriber.subscription != subs
        })
        ambManager.ambClient.unsubscribe(subs)
    }
    
    // Force a publication to a channel
    func publish(onChannel channel: String, jsonMessage message: String) {
        for subscriber in subscribers where subscriber.channel == channel {
            subscriber.subscriber.onMessage(message, fromChannel: channel)
        }
    }
    
    internal static func messageToJSON(message msg: [AnyHashable:Any]) -> String? {
        do {
            let msgData = try JSONSerialization.data(withJSONObject: msg, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let msgString = String(data: msgData, encoding: .utf8) {
                return msgString
            }
        } catch let err {
            Logger.default.logError("Error \(err) decoding message: \(msg)")
        }
        return nil
    }
}
