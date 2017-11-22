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
    
    func subscribe(_ channelName: String, messages messageHandler: @escaping ((NOWAMBSubscription?, [AnyHashable : Any]?) -> Void)) -> NOWAMBSubscription {
        let subscription: NOWAMBSubscription = fayeClient.subscribe(channelName, messages: messageHandler)
        return subscription
    }
    
    func unsubscribe(_ subscription: NOWAMBSubscription) {
        fayeClient.unsubscribe(subscription)
    }
    
}
