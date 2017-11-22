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
    
    var encoder: JSONEncoder?
    var decoder: JSONDecoder?
    
    override func setUp() {
        super.setUp()

        encoder = JSONEncoder()
        encoder?.dateEncodingStrategy = .millisecondsSince1970

        decoder = JSONDecoder()
        decoder?.dateDecodingStrategy = .millisecondsSince1970
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
        let json = """
        {
          "type": "systemTextMessage",
          "data": {
            "sessionId": 1,
            "sendTime": 0,
            "receiveTime": 0,
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
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlBoolean)
        let boolObj = obj as! BooleanControlMessage
        XCTAssert(boolObj.data.richControl.uiType == "Boolean")
        XCTAssert(boolObj.data.richControl.model.type == "field")
        XCTAssert(boolObj.data.richControl.uiMetadata.label == "Would you like to create an incident?")
        XCTAssert(boolObj.data.richControl.uiMetadata.required == true)
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
    
    func testConsumerTextMessage() {
        let ctm = ConsumerTextMessage(withData: RichControlData(sessionId: 1,
                                                                controlData: ConsumerTextMessage.ControlWrapper(uiType: "TopicPicker")))
        do {
            let jsonData = try encoder!.encode(ctm)
            let jsonString = String(data: jsonData, encoding: .utf8)
            Logger.default.logInfo("JSON: \(jsonString!)")
            
            XCTAssertTrue(jsonString!.contains("\"type\":\"consumerTextMessage\""))
            XCTAssertTrue(jsonString!.contains("\"uiType\":\"TopicPicker\""))

            // make a new instance from the JSON, then decode that and compare to the original
            let clone = try decoder!.decode(ConsumerTextMessage.self, from: jsonData)
            let cloneData = try encoder!.encode(clone)
            let cloneString = String(data: cloneData, encoding: .utf8)
            XCTAssertEqual(jsonString, cloneString)
        } catch let error {
            Logger.default.logInfo(error.localizedDescription)
        }
        
    }

    let jsonInitStart = """
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
    
    func testInitEventFromJSON() {
        
        let obj = CBDataFactory.channelEventFromJSON(jsonInitStart)
        XCTAssertNotNil(obj)
        XCTAssert(obj.eventType == .channelInit)
        
        let initObj = obj as? InitMessage
        XCTAssert(initObj != nil)
        XCTAssert(initObj?.data.actionMessage.systemActionName == "init")
        XCTAssert(initObj?.data.actionMessage.loginStage == "Start")
        XCTAssert(initObj?.data.actionMessage.contextHandshake.serverContextRequest.count == 7)
    }
    
    func testActionMessage() {
        
        let jsonData = jsonInitStart.data(using: .utf8)
        let decoder = JSONDecoder()
        do {
            let actionMessage = try decoder.decode(ActionMessage.self, from: jsonData!) as ActionMessage
            XCTAssert(actionMessage.data.actionMessage.type == "Init")
        } catch let error {
            Logger.default.logInfo(error.localizedDescription)
            XCTAssert(false)
        }
    }
    
    func testTopicPickerMessage() {
        let topicPicker = TopicPickerMessage(forSession: 1, withValue: "system")
        
        do {
            let jsonData = try encoder!.encode(topicPicker)
            let jsonString: String = String(data: jsonData, encoding: .utf8)!
            Logger.default.logInfo(jsonString)
            
            XCTAssert(jsonString.contains("\"type\":\"consumerTextMessage\""))
            XCTAssert(jsonString.contains("\"type\":\"topic\""))
            XCTAssert(jsonString.contains("\"uiType\":\"TopicPicker\""))
            XCTAssert(jsonString.contains("\"value\":\"system\""))
            
            let clone = try decoder!.decode(TopicPickerMessage.self, from: jsonData)
            let cloneData = try encoder!.encode(clone)
            let cloneString = String(data: cloneData, encoding: .utf8)
            XCTAssertEqual(cloneString, jsonString)
        } catch let error {
            Logger.default.logInfo(error.localizedDescription)
        }
    }
}
