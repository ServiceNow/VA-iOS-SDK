//
//  CBTestMessageHandler.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class MockState: ChatState {
    var state = CBChannelEvent.channelEventUnknown
    
    init() {
        let user = CBUser(id: "9927", token: "938457hge98", name: "marc", consumerId: "marc.attinasi", consumerAccountId: "marc.attinasi@servicenow.com")
        let vendor = CBVendor(name: "ServiceNow", vendorId: "001", consumerId: "marc.attinasi", consumerAccountId: "marc.attinasi@servicenow.com")
        let session = CBSession(id: "1", user: user, vendor: vendor)
        
        super.init(forSession: session, initialState: ChatStates.Disconnected)
    }
    
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

class MockAMBClient: AMBChatClient {
    override func login(userName: String, password: String, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    override func publish(onChannel channel: String, jsonMessage message: String) {
        super.publish(onChannel: channel, jsonMessage: message)
    }
}

class TestMessageHandler: XCTestCase {
    
    var ambClient: MockAMBClient?
    var chatState: MockState?
    var chatStore: ChatDataStore?
    var messageHandler: ChatMessageHandler?
    
    override func setUp() {
        super.setUp()

        chatState = MockState()
        chatStore = ChatDataStore(storeId: "TEST001")
        ambClient = MockAMBClient(withEndpoint: URL(string: CBData.config.url)!)
        ambClient?.login(userName: "admin", password: "snow2004", completionHandler: { (success) in
            Logger.default.logInfo("AMB Login Completed {\(success ? "success" : "failure")}")
            if success {
                self.messageHandler = ChatMessageHandler(withAmb: self.ambClient!, withDataStore: self.chatStore!, withState: self.chatState!)
            }
        })
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
        let json = """
        {
          "type": "systemTextMessage",
          "data": {
            "sessionId": "1",
            "sendTime": 0,
            "receiveTime": 0,
            "direction": "outbound",
            "richControl": {
              "uiType": "Boolean",
              "uiMetadata": {
                "label": "Would you like to create an incident?",
                "required": true
              },
              "model": {
                "name": "init_create_incident",
                "type": "field"
              }
            },
            "messageId": "d30c8342-1e78-47aa-886e-d6627c092691"
          }
        }
        """
        ambClient?.publish(onChannel: channel.name, jsonMessage: json)
        
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }

        NotificationCenter.default.removeObserver(observer1)
        NotificationCenter.default.removeObserver(observer2)
    }
    
        fileprivate func observeControlChangesAndSucceed(_ expect: XCTestExpectation) -> NSObjectProtocol {
            return NotificationCenter.default.addObserver(forName: ChatNotification.name(forKind: .booleanControl),
                                                          object: nil, queue: nil) { notification in
                let info = notification.userInfo as! [String: Any]
                let notificationData = info["state"] as! BooleanControlMessage
                
                XCTAssert(notificationData.controlType == .controlBoolean)
                XCTAssertEqual(notificationData.data.messageId, "d30c8342-1e78-47aa-886e-d6627c092691")
                
                expect.fulfill()
            }
        }
    
        fileprivate func observeDateControlChangesAndFail() -> NSObjectProtocol {
            return NotificationCenter.default.addObserver(forName: ChatNotification.name(forKind: .dateControl),
                                                          object: nil, queue: nil) { notification in
                XCTAssert(false) // boolean control should not be delivered here!
            }
        }
    
    // swiftlint:disable:next function_body_length
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
            "sessionId": "1",
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
