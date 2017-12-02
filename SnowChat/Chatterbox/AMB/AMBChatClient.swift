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

private func logger() -> Logger { return Logger.logger(for: "AMBClient") }

class AMBChatClient {
    
    private lazy var ambManager: APIManager = {
        let url = endpoint
        let instance = ServerInstance(instanceURL: url)
        let manager = APIManager(instance: instance)
        return manager
    }()
    
    private var endpoint: URL
    private var currentState: AMBState = .signedOut
    private var subscribers = [(channel: String, subscriber: AMBListener, subscription: NOWAMBSubscription)]()
    
    enum AMBState {
        case signedOut
        case signedIn
    }
    
    init(withEndpoint url: URL) {
        endpoint = url
    }
    
    func login(userName: String, password: String, completionHandler: @escaping (Error?) -> Void) {
        ambManager.logIn(username: userName, password: password) { [weak self] error in
            guard let me = self else {
                logger().logError("AMBChatClient went away while processing login")
                return
            }
            
            if error == nil {
                me.currentState = .signedIn
            } else {
                me.currentState = .signedOut
            }
            
            completionHandler(error)
        }
    }
    
    func subscribe(forChannel channel: String, receiver: AMBListener) {
        let subscription = ambManager.ambClient.subscribe(channel) { [weak self] (subscription, message) in
            guard let msg = message else {
                logger().logError("Nil-message received on channel \(channel)")
                return
            }
            
            guard let me = self else {
                logger().logError("AMBChatClient no longer valid while processing message from AMB")
                return
            }
            
            me.handleMessage(subscription, channel, msg, receiver)
        }
        
        subscribers.append((channel: channel, subscriber: receiver, subscription: subscription))
    }
    
    func unsubscribe(fromChannel channel: String, receiver: AMBListener) {
        for subscription in subscribers {
            if subscription.channel == channel && subscription.subscriber.id == receiver.id {
                unsubscribe(subscription: subscription.subscription)
            }
        }
    }
    
    func publish<T>(channel: String, message: T) where T: Encodable {
        let encoder = CBData.jsonEncoder
        do {
            let jsonData = try encoder.encode(message)
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    logger().logInfo("AMB Channel: \(channel)\nAMB Message \(jsonString)")
                }
                ambManager.ambClient.send(message: dict, toChannel: channel)
            }
        } catch let err {
            logger().logError("Error publishing: \(err)")
        }
        
    }
    
    internal func handleMessage(_ subscription: NOWAMBSubscription?, _ channel: String, _ message: [AnyHashable : Any], _ receiver: AMBListener ) {
        if let msgString = AMBChatClient.messageToJSON(message: message) {
            logger().logInfo("Incoming Message: \(msgString)")
            receiver.onMessage(msgString, fromChannel: channel)
        } else {
            logger().logError("Error getting JSON from message: \(message)")
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
            logger().logError("Error \(err) decoding message: \(msg)")
        }
        return nil
    }
}
