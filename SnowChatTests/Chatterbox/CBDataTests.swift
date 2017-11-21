//
//  CBDataTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class TestControlData: CBControlData {
    let id: String
    let controlType: CBControlType
    
    init() {
        id = "123"
        controlType = .controlTypeUnknown
    }
}

class CBDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testControlDataInit() {
        let cd = TestControlData()
        XCTAssert(cd.id == "123")
        XCTAssert(cd.controlType == .controlTypeUnknown)
    }
    
    func testBooleanDataInit() {
        let bc = CBBooleanData(withId: "123", withValue: true)
        XCTAssert(bc.id == "123")
        XCTAssert(bc.controlType == .controlBoolean)
        XCTAssert(bc.value == true)
    }
    
    func testDateDataInit() {
        let date = Date()
        let bc = CBDateData(withId: "123", withValue: date)
        XCTAssert(bc.id == "123")
        XCTAssert(bc.controlType == .controlDate)
        XCTAssert(bc.value == date)
    }
    
    func testInputDataInit() {
        let input = "Where is my money?"
        let bc = CBInputData(withId: "123", withValue: input)
        XCTAssert(bc.id == "123")
        XCTAssert(bc.controlType == .controlInput)
        XCTAssert(bc.value == input)
    }
    
    func testChannelEvent() {
        let data = CBChannelRefreshData(status: 100)
        XCTAssert(data.eventType == .channelRefresh)
        XCTAssert(data.status == 100)
    }
    
    func testBooleanFromJSON() {
        let json = "{\"type\":\"booleanControl\",\"value\":0}"
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlBoolean)
        let boolObj = obj as! CBBooleanData
        XCTAssert(boolObj.value == false)
    }
    
    func testDateFromJSON() {
        let date = Date()
        let json = "{\"type\":\"dateControl\",\"value\":\(date.timeIntervalSinceReferenceDate)}"
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlDate)
        let dateObj = obj as! CBDateData
        XCTAssert(dateObj.value == date)
    }
    
    func testInputFromJSON() {
        let val = "Are we not men?"
        let json = "{\"type\":\"inputControl\",\"value\":\"\(val)\"}"
        var obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlInput)
        let inputObj = obj as! CBInputData
        XCTAssert(inputObj.value == val)
        
        let badJson = "{\"type\":\"inputControl\",\"value(*&\":false}"
        obj = CBDataFactory.controlFromJSON(badJson)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlTypeUnknown)
        let unknownObj = obj as? CBControlDataUnknown
        XCTAssert(unknownObj != nil)
    }
    
    func testInvalidTypeFromJSON() {
        let val = "WTF?"
        let json = "{\"typo\":\"unknownControl\",\"value\":\"\(val)\"}"
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlTypeUnknown)
        let inputObj = obj as? CBControlDataUnknown
        XCTAssertNotNil(inputObj)
    }
    
    func testInitEventFromJSON() {
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
        let obj = CBDataFactory.channelEventFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.eventType == .channelInit)
        
        let initObj = obj as? InitMessage
        XCTAssert(initObj != nil)
        XCTAssert(initObj?.data.actionMessage.systemActionName == "init")
        XCTAssert(initObj?.data.actionMessage.loginStage == "Start")
        XCTAssert(initObj?.data.actionMessage.contextHandshake.serverContextRequest.count == 7)
    }
    
    func testActionMessage() {
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
        let jsonData = json.data(using: .utf8)
        let decoder = JSONDecoder()
        do {
            let actionMessage = try decoder.decode(ActionMessage.self, from: jsonData!) as ActionMessage
            XCTAssert(actionMessage.data.actionMessage.type == "Init")
        }
        catch let error {
            debugPrint(error)
            XCTAssert(false)
        }
        
        
    }
}
