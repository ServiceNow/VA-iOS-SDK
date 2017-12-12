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
    
    func client(_ client: AMBChatClient, didReceiveMessage message: String, fromChannel channel: String)
}

private let logger: Logger = Logger.logger(for: "AMBClient")

class AMBChatClient {
    
    private lazy var ambManager: APIManager = {
        let url = endpoint
        let instance = ServerInstance(instanceURL: url)
        let manager = APIManager(instance: instance)
        return manager
    }()
    
    private var endpoint: URL
    private var currentState: AMBState = .signedOut
    private var subscribers = [(channel: String, receiver: AMBListener, subscription: NOWAMBSubscription)]()
    
    enum AMBState {
        case signedOut
        case signedIn
    }
    
    init(withEndpoint url: URL) {
        endpoint = url
    }
    
    func login(userName: String, password: String, completion: @escaping (Error?) -> Void) {
        ambManager.logIn(username: userName, password: password) { [weak self] error in
            guard let strongSelf = self else {
                logger.logError("AMBChatClient went away while processing login")
                return
            }
            
            if error == nil {
                strongSelf.currentState = .signedIn
            } else {
                strongSelf.currentState = .signedOut
            }
            
            completion(error)
        }
    }
    
    func subscribe(_ receiver: AMBListener, toChannel channel: String) {
        let subscription = ambManager.ambClient.subscribe(channel) { [weak self] (subscription, message) in
            guard let message = message else {
                // NOTE: this seems to happen in normal conditions- why?
                logger.logInfo("Nil-message received on channel \(channel)")
                return
            }
            
            guard let strongSelf = self else {
                logger.logError("AMBChatClient no longer valid while processing message from AMB")
                return
            }
            
            strongSelf.didReceive(message, fromChannel: channel, forReceiver: receiver, subscription: subscription)
        }
        
        subscribers.append((channel: channel, receiver: receiver, subscription: subscription))
    }
    
    func unsubscribe(_ receiver: AMBListener, fromChannel channel: String) {
        for subscriber in subscribers {
            if subscriber.channel == channel && subscriber.receiver.id == receiver.id {
                unsubscribe(subscription: subscriber.subscription)
            }
        }
    }
    
    func publish<T>(message: T, toChannel channel: String) where T: Encodable {
        let encoder = CBData.jsonEncoder
        do {
            let jsonData = try encoder.encode(message)
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                
                if logger.enabled, let jsonString = String(data: jsonData, encoding: .utf8) {
                    logger.logInfo("Publishing to AMB Channel: \(channel): \(jsonString)")
                }
                
                ambManager.ambClient.send(message: dict, toChannel: channel)
            }
        } catch let err {
            logger.logError("Error publishing: \(err)")
        }
        
    }
    
    static func toJSONString(fromDictionary: [AnyHashable:Any]) -> String? {
        do {
            let msgData = try JSONSerialization.data(withJSONObject: fromDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let msgString = String(data: msgData, encoding: .utf8) {
                return msgString
            }
        } catch let err {
            logger.logError("Error \(err) decoding message: \(fromDictionary)")
        }
        return nil
    }

    internal func didReceive(_ message: [AnyHashable : Any], fromChannel channel: String, forReceiver receiver: AMBListener, subscription: NOWAMBSubscription?) {
        if let msgString = AMBChatClient.toJSONString(fromDictionary: message) {
            logger.logInfo("Incoming AMB Message: \(msgString)")
            
            receiver.client(self, didReceiveMessage: msgString, fromChannel: channel)
        }
    }
    
    internal func unsubscribe(subscription: NOWAMBSubscription) {
        subscribers = subscribers.filter({ (subscriber) -> Bool in
            return subscriber.subscription != subscription
        })
        ambManager.ambClient.unsubscribe(subscription)
    }
}
