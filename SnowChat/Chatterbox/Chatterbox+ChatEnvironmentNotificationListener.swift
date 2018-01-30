//
//  Chatterbox+ChatEnvironmentNotificationListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/30/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension Chatterbox: ChatEnvironmentNotificationListener {
    
    // MARK: - Environment Change Notification Handler
    
    func registerForEnvironmentNotifications() {
        environmentSubscription = ChatEnvironmentNotificationCenter.default.addListener(self)
    }
    
    func unregisterEnvironmentNotifications() {
        if let environmentSubscription = environmentSubscription {
            ChatEnvironmentNotificationCenter.default.removeListener(subscriptionId: environmentSubscription)
        }
    }
    
    func applicationWillEnterBackground(_ notification: ChatEnvironmentNotificationCenter) {
        logger.logInfo("Application going into background")
        apiManager.applicationWillEnterBackground()
    }
    
    func applicationDidEnterForeground(_ notification: ChatEnvironmentNotificationCenter) {
        logger.logInfo("Application returned to foreground")
        
        apiManager.applicationDidEnterForeground()
        
        syncConversation()
    }
    
    func networkReachable(_ notification: ChatEnvironmentNotificationCenter) {
        logger.logInfo("Network connection restored")
        
        apiManager.networkReachable()
        
        syncConversation()
    }
    
    func networkUnreachable(_ notification: ChatEnvironmentNotificationCenter) {
        logger.logInfo("Network connection lost")

        apiManager.networkUnreachable()
        
        // TODO: tell UI
    }
    
    func instanceReachable(_ notification: ChatEnvironmentNotificationCenter) {
        // same as network for now...
        networkReachable(notification)
    }
    
    func instanceUnreachable(_ notification: ChatEnvironmentNotificationCenter) {
        // same as network for now...
        networkReachable(notification)
    }
}
