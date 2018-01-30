//
//  ChatNotificationCenterTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 1/29/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import XCTest
@testable import SnowChat

class TestListener: ChatEnvironmentNotificationListener {
    static var counter = 0
    var serial = 0
    var enteredBackground = false
    var enteredForeground = false
    var netUnreachable = false
    var netReachable = false
    var instUnreachable = false
    var instReachable = false
    
    func applicationWillEnterBackground(_ notification: ChatEnvironmentNotificationCenter) {
        enteredBackground = true
        
        TestListener.counter += 1
        serial = TestListener.counter
    }
    
    func applicationDidEnterForeground(_ notification: ChatEnvironmentNotificationCenter) {
        enteredForeground = true
        TestListener.counter += 1
        serial = TestListener.counter
    }
    
    func networkReachable(_ notification: ChatEnvironmentNotificationCenter) {
        netReachable = true
        TestListener.counter += 1
        serial = TestListener.counter
    }
    
    func networkUnreachable(_ notification: ChatEnvironmentNotificationCenter) {
        netUnreachable = true
        TestListener.counter += 1
        serial = TestListener.counter
    }
    
    func instanceReachable(_ notification: ChatEnvironmentNotificationCenter) {
        instReachable = true
        TestListener.counter += 1
        serial = TestListener.counter
    }
    
    func instanceUnreachable(_ notification: ChatEnvironmentNotificationCenter) {
        instUnreachable = true
        TestListener.counter += 1
        serial = TestListener.counter
    }
}

class ChatNotificationCenterTests: XCTestCase {
    
    func testAddRemoveListener() {
        let testListener = TestListener()
        let notifier = ChatEnvironmentNotificationCenter.default
        let subscription = notifier.addListener(testListener)
        XCTAssertNotNil(notifier.subscriptions.count == 1)
        XCTAssertTrue((notifier.subscriptions.first(where: { (s) -> Bool in
            return s.id == subscription
        }) != nil))
        
        notifier.removeListener(subscriptionId: subscription)
        XCTAssertNotNil(notifier.subscriptions.count == 0)
        XCTAssertTrue((notifier.subscriptions.first(where: { (s) -> Bool in
            return s.id == subscription
        }) == nil))
    }
    
    func testListenerNotified() {
        let testListener = TestListener()
        let notifier = ChatEnvironmentNotificationCenter.default
        let subscription = notifier.addListener(testListener)
        
        notifier.notifyNetworkReachability(true)
        XCTAssertTrue(testListener.netReachable)
        XCTAssertFalse(testListener.netUnreachable)
        XCTAssertFalse(testListener.enteredForeground)
        XCTAssertFalse(testListener.enteredBackground)
        XCTAssertFalse(testListener.instUnreachable)
        XCTAssertFalse(testListener.instReachable)
        
        notifier.notifyNetworkReachability(false)
        XCTAssertTrue(testListener.netUnreachable)
        XCTAssertFalse(testListener.enteredForeground)
        XCTAssertFalse(testListener.enteredBackground)
        XCTAssertFalse(testListener.instUnreachable)
        XCTAssertFalse(testListener.instReachable)

        let notification = Notification(name: .UIApplicationDidBecomeActive)
        notifier.applicationDidBecomeActiveNotification(notification)
        XCTAssertTrue(testListener.enteredForeground)
        XCTAssertFalse(testListener.enteredBackground)
        XCTAssertFalse(testListener.instUnreachable)
        XCTAssertFalse(testListener.instReachable)

        notifier.applicationWillResignActiveNotification(notification)
        XCTAssertTrue(testListener.enteredBackground)
        XCTAssertFalse(testListener.instUnreachable)
        XCTAssertFalse(testListener.instReachable)

        notifier.removeListener(subscriptionId: subscription)
    }
    
    func testNotificationOrder() {
        let testListeners = [TestListener(), TestListener(), TestListener()]
        let notifier = ChatEnvironmentNotificationCenter.default
        var subscriptions = [ChatEnvironmentNotificationCenter.ChatNotificationSubscription]()
        
        testListeners.forEach { (listener) in
            subscriptions.append(notifier.addListener(listener))
        }
        
        notifier.notifyNetworkReachability(true)
        XCTAssertTrue(testListeners[0].serial < testListeners[1].serial && testListeners[1].serial < testListeners[2].serial)
        XCTAssertTrue(testListeners[0].netReachable == true && testListeners[1].netReachable == true && testListeners[2].netReachable == true)
        
        let notification = Notification(name: .UIApplicationDidBecomeActive)
        notifier.applicationDidBecomeActiveNotification(notification)

        
    }
}
