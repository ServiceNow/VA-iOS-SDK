//
//  AMBClient.swift
//  SnowChat
//
//  Created by Will Lisac on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import Alamofire
import SNOWAMBClient

// A wrapped; self contained AMB client
// Probably remove this?

private let logger = Logger.logger(for: "AMBClient")

internal class AMBClient: NSObject {
    
    private let fayeClient: SNOWAMBClient
    
    init(sessionManager: SessionManager, baseURL: URL) {
        let httpClient = AMBHTTPClient(sessionManager: sessionManager, baseURL: baseURL)
        fayeClient = SNOWAMBClient(httpClient: httpClient)
    
        super.init()
    }
    
    // MARK: - Reachability
    
    internal func networkReachable() {
        fayeClient.reconnectIfNeeded()
    }
    
    internal func networkUnreachable() {
    
    }
    
    // MARK: - Notification Handling
    
    internal func applicationWillResignActiveNotification() {
        fayeClient.paused = true
    }
    
    internal func applicationDidBecomeActiveNotification() {
        fayeClient.paused = false
    }
    
    // MARK: - Faye Method Proxies
    
    func connect() {
        fayeClient.connect()
    }
    
    // FIXME: Don't go from data, to string, to dictionary, to JSON, to string :)
    // Need to remove when new AMB client is ready
    func subscribe(_ channelName: String, messages messageHandler: @escaping SNOWAMBMessageHandler) -> SNOWAMBSubscription {
        let subscription : SNOWAMBSubscription = fayeClient.subscribe(channel: channelName, messageHandler: { (result, subscription) in
            switch result {
            case .success:
                if let message = result.value {
                    logger.logInfo("Incoming AMB Message: \(message.jsonDataString)")
                    messageHandler(result, subscription)
                }
            case .failure:
                messageHandler(result, subscription)
            }
        })
        return subscription
    }

    private static func toJSONString(fromDictionary: [AnyHashable : Any]) -> String? {
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
    
    func unsubscribe(_ subscription: SNOWAMBSubscription) {
        fayeClient.unsubscribe(subscription: subscription)
    }
    
    func sendMessage(_ message: [String: Any], toChannel channel: String) {
        fayeClient.publishMessage(message, toChannel: channel, withExtension:[:],
                                  completion: { (result) in
                                    switch result {
                                    case .success:
                                        logger.logInfo("published message successfully")
                                        //TODO: Implement handler here
                                    case .failure:
                                        logger.logInfo("failed to publish message")
                                        //TODO: same
                                    }
        })
    }
    
    func sendMessage<T>(_ message: T, toChannel channel: String, encoder: JSONEncoder) where T: Encodable {
        do {
            let jsonData = try encoder.encode(message)
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                
                if logger.enabled, let jsonString = String(data: jsonData, encoding: .utf8) {
                    logger.logInfo("Publishing to AMB Channel: \(channel): \(jsonString)")
                }
                
                sendMessage(dict, toChannel: channel)
            }
        } catch let err {
            logger.logError("Error publishing: \(err)")
        }
    }
}
