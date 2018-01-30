//
//  ChatNotificationCenter.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/29/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

protocol ChatEnvironmentNotificationListener: AnyObject {
    
    func applicationWillEnterBackground(_ notification: ChatEnvironmentNotificationCenter)
    func applicationDidEnterForeground(_ notification: ChatEnvironmentNotificationCenter)
    
    func networkReachable(_ notification: ChatEnvironmentNotificationCenter)
    func networkUnreachable(_ notification: ChatEnvironmentNotificationCenter)
    
    func instanceReachable(_ notification: ChatEnvironmentNotificationCenter)
    func instanceUnreachable(_ notification: ChatEnvironmentNotificationCenter)
}

class ChatEnvironmentNotificationCenter: Equatable {
    
    static func == (lhs: ChatEnvironmentNotificationCenter, rhs: ChatEnvironmentNotificationCenter) -> Bool {
        return lhs.id == rhs.id
    }
    
    typealias ChatNotificationSubscription = String
    
    static var `default`: ChatEnvironmentNotificationCenter = ChatEnvironmentNotificationCenter()
    
    internal var id = CBData.uuidString()
    internal var subscriptions = [(listener: ChatEnvironmentNotificationListener, id: String)]()
    private let reachabilityManager = NetworkReachabilityManager()
    private var instanceReachabilityManager: NetworkReachabilityManager?

    init(instance: ServerInstance? = nil) {
        if instance != nil, let hostUrl = instance?.instanceURL.absoluteString {
            instanceReachabilityManager = NetworkReachabilityManager(host: hostUrl)
            subscribeToInstanceReachabilityChanges()
        }
        subscribeToAppStateChanges()
        subscribeToNetworkReachabilityChanges()
    }
    
    public func addListener(_ listener: ChatEnvironmentNotificationListener) -> ChatNotificationSubscription {
        let subscription = (listener: listener, id: CBData.uuidString())
        subscriptions.append(subscription)
        return subscription.id
    }
    
    public func removeListener(subscriptionId: String) {
        if let index = subscriptions.index(where: { listener -> Bool in
            return listener.id == subscriptionId
        }) {
            subscriptions.remove(at: index)
        }
    }
    
    private func subscribeToAppStateChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNotification(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    @objc internal func applicationWillResignActiveNotification(_ notification: Notification) {
        subscriptions.forEach { listener in
            listener.listener.applicationWillEnterBackground(self)
        }
    }
    
    @objc internal func applicationDidBecomeActiveNotification(_ notification: Notification) {
        subscriptions.forEach { listener in
            listener.listener.applicationDidEnterForeground(self)
        }
    }

    private func subscribeToNetworkReachabilityChanges() {
        guard let reachabilityManager = reachabilityManager else { return }
        reachabilityManager.startListening()
        
        reachabilityManager.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            strongSelf.notifyNetworkReachability(reachabilityManager.isReachable)
        }
    }

    private func subscribeToInstanceReachabilityChanges() {
        guard let reachabilityManager = instanceReachabilityManager else { return }
        reachabilityManager.startListening()
        
        reachabilityManager.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            strongSelf.notifyInstanceReachability(reachabilityManager.isReachable)
        }
    }
    
    internal func notifyNetworkReachability(_ reachable: Bool) {
        self.subscriptions.forEach({ subscription in
            if reachable {
                subscription.listener.networkReachable(self)
            } else {
                subscription.listener.networkUnreachable(self)
            }
        })
    }
    
    internal func notifyInstanceReachability(_ reachable: Bool) {
        self.subscriptions.forEach({ subscription in
            if reachable {
                subscription.listener.instanceReachable(self)
            } else {
                subscription.listener.instanceUnreachable(self)
            }
        })
    }
}
