//
//  AMBClient.swift
//  SnowChat
//
//  Created by Will Lisac on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import Alamofire
import AMBClient

// A wrapped; self contained AMB client
// Probably remove this?

private let logger = Logger(forCategory: "AMBClient", level: .Info)

internal class AMBClient: NSObject {
    
    private let fayeClient: NOWFayeClient
    private let reachabilityManager = NetworkReachabilityManager()
    
    init(sessionManager: SessionManager, baseURL: URL) {
        let httpClient = AMBHTTPClient(sessionManager: sessionManager, baseURL: baseURL)
        fayeClient = NOWFayeClient(httpClient: httpClient)
    
        super.init()
        
        setupNotificationObserving()
    }
    
    // MARK: - Reachability
    
    private func setupReachabilityMonitoring() {
        guard let reachabilityManager = reachabilityManager else { return }
        reachabilityManager.startListening()
        
        reachabilityManager.listener = { [weak self] status in
            if reachabilityManager.isReachable {
                self?.fayeClient.reconnectIfNeeded()
            }
        }
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNotification(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    @objc private func applicationWillResignActiveNotification(_ notification: Notification) {
        fayeClient.pause()
    }
    
    @objc private func applicationDidBecomeActiveNotification(_ notification: Notification) {
        fayeClient.resume()
    }
    
    // MARK: - Faye Method Proxies
    
    @discardableResult func connect() -> Bool {
        return fayeClient.connect()
    }
    
    // FIXME: Don't go from data, to string, to dictionary, to JSON, to string :)
    // Need to remove when new AMB client is ready
    func subscribe(_ channelName: String, messages messageHandler: @escaping ((NOWAMBSubscription?, String) -> Void)) -> NOWAMBSubscription {
        let subscription: NOWAMBSubscription = fayeClient.subscribe(channelName) { (subscription, message) in
            
            guard let message = message else {
                // NOTE: this seems to happen in normal conditions- why?
                logger.logInfo("Nil-message received on channel \(channelName)")
                return
            }
            
            if let messageString = AMBClient.toJSONString(fromDictionary: message) {
                logger.logInfo("Incoming AMB Message: \(messageString)")
                messageHandler(subscription, messageString)
            }

        }
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
    
    func unsubscribe(_ subscription: NOWAMBSubscription) {
        fayeClient.unsubscribe(subscription)
    }
    
    func sendMessage(_ message: [String: Any], toChannel channel: String ) {
        fayeClient.sendMessage(message, toChannel: channel)
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
