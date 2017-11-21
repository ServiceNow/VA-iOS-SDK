//
//  CBTestMessageHandler.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class MockState : ChatState {
    var state = CBChannelEvent.channelEventUnknown
    
    override func onChannelInit(forChannel: CBChannel, withEventData data: InitMessage) {
        state = .channelInit
    }
    
    override func onChannelOpen(forChannel: CBChannel, withEventData: CBChannelOpenData) {
        state = .channelOpen
    }
    
    override func onChannelClose(forChannel: CBChannel, withEventData: CBChannelCloseData) {
        state = .channelClose
    }
    
    override func onChannelRefresh(forChannel: CBChannel, withEventData: CBChannelRefreshData) {
        state = .channelRefresh
    }
}

class TestMessageHandler : XCTestCase {
    
    var ambClient: AMBClient? = nil
    var chatStore: ChatDataStore? = nil
    var chatState: MockState? = nil
    var messageHandler: ChatMessageHandler? = nil
    
    override func setUp() {
        super.setUp()

        chatState = MockState()
        chatStore = ChatDataStore(storeId: "TEST001")
        ambClient = AMBClient()
        messageHandler = ChatMessageHandler(withAmb: ambClient!, withDataStore: chatStore!, withState: chatState!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func testBooleanControlMessagePumpedToHandler() {
        let expect = expectation(description: "Expect Notification for Boolean Control")

        let channel = CBChannel(name: "testChannel")
        messageHandler?.attach(toChannel: channel)
        
        let observer1 = observeControlChangesAndSucceed(expect)
        let observer2 = observeDateControlChangesAndFail()
        
        // pretend a message came in via AMB for a booleanControl
        let json = "{\"type\":\"booleanControl\",\"value\":1}"
        ambClient?.publish(onChannel: channel.name, jsonMessage: json)
        
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }

        NotificationCenter.default.removeObserver(observer1)
        NotificationCenter.default.removeObserver(observer2)
    }
    
        fileprivate func observeControlChangesAndSucceed(_ expect: XCTestExpectation) -> NSObjectProtocol {
            return NotificationCenter.default.addObserver(forName: ChatNotification.name(forKind: .booleanControl),
                                                          object: nil, queue: nil)
            { notification in
                let info = notification.userInfo as! Dictionary<String, Any>
                let notificationData = info["state"] as! CBBooleanData
                
                XCTAssert(notificationData.controlType == .controlBoolean)
                XCTAssertEqual(notificationData.value, true)
                
                expect.fulfill()
            }
        }
    
        fileprivate func observeDateControlChangesAndFail() -> NSObjectProtocol {
            return NotificationCenter.default.addObserver(forName: ChatNotification.name(forKind: .dateControl),
                                                          object: nil, queue: nil)
            { notification in
                XCTAssert(false) // boolean control should not be delivered here!
            }
        }
    
    func testEventMessagePumpedToStateHandler() {
        let channel = CBChannel(name: "testChannel")
        messageHandler?.attach(toChannel: channel)
        
        // pretend a message came in via AMB for an Init
        let json = """
        {
          "type": "actionMessage",
          "data": {
            "@class": ".ActionMessageDto",
            "messageId": "687e15f4-ffa9-497e-9d7b- 83a0c714100a",
            "topicId": 1,
            "taskId": 1,
            "sessionId": 1,
            "direction": "outbound",
            "sendTime": 0,
            "receiveTime": 0,
            "actionMessage": {
              "type": "Init",
              "loginStage": "Start",
              "systemActionName": "init",
              "contextHandshake": {
                "deviceId": "+15109968676",
                "ctxHandShakeId": 1,
                "clientContextRes": {},
                "serverContextReq": {
                  "DeviceType": {
                    "updateType": "push",
                    "updateFrequency": "once"
                  },
                  "permissionToUsePhoto": {
                    "updateType": "push",
                    "updateFrequency": "once"
                  },
                  "MobileAppVersion": {
                    "updateType": "push",
                    "updateFrequency": "once"
                  },
                  "MobileOS": {
                    "updateType": "push",
                    "updateFrequency": "once"
                  },
                  "location": {
                    "updateType": "push",
                    "updateFrequency": "every minute"
                  },
                  "deviceTimeZone": {
                    "updateType": "push",
                    "updateFrequency": "once"
                  },
                  "permissionToUseCamera": {
                    "updateType": "push",
                    "updateFrequency": "once"
                  }
                }
              }
            }
          }
        }
        """
        messageHandler?.onMessage(json, fromChannel: channel.name)

        XCTAssert(chatState!.state == .channelInit)
        
    }
    
}
