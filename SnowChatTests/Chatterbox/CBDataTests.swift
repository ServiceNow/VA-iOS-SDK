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
    var direction: MessageDirection { return .fromClient }
    var uniqueId: String { return id }
    
    var messageId: String
    var conversationId: String?
    var messageTime: Date
    
    let id: String
    let controlType: CBControlType
    
    init() {
        id = "123"
        controlType = .unknown
        messageId = CBData.uuidString()
        messageTime = Date()
    }
}

class CBDataTests: XCTestCase {
    
    var encoder: JSONEncoder?
    var decoder: JSONDecoder?
    
    override func setUp() {
        super.setUp()

        encoder = CBData.jsonEncoder

        decoder = CBData.jsonDecoder
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testControlDataInit() {
        let cd = TestControlData()
        XCTAssert(cd.id == "123")
        XCTAssert(cd.controlType == .unknown)
    }
    
    func testInvalidTypeFromJSON() {
        let val = "WTF?"
        let json = "{\"typo\":\"unknownControl\",\"value\":\"\(val)\"}"
        let obj = ChatDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .unknown)
        let inputObj = obj as? CBControlDataUnknown
        XCTAssertNotNil(inputObj)
    }

    func testBooleanMessageExample() {
        let boolObj = ExampleData.exampleBooleanControlMessage()
        XCTAssertNotNil(boolObj)
        XCTAssert(boolObj.controlType == .boolean)
        XCTAssert(boolObj.data.richControl?.uiType == "Boolean")
        XCTAssert(boolObj.data.richControl?.model?.type == "field")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.label == "Would you like to create an incident?")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.required == true)
    }
    
    func testInputMessageExample() {
        let obj = ExampleData.exampleInputControlMessage()
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .input)
        XCTAssert(obj.data.richControl?.uiType == "InputText")
        XCTAssert(obj.data.richControl?.model?.type == "field")
        XCTAssert(obj.data.richControl?.uiMetadata?.label == "Please enter a short description of the issue you would like to report.")
        XCTAssert(obj.data.richControl?.uiMetadata?.required == true)
    }
    
    func testPickerMessageExample() {
        let obj = ExampleData.examplePickerControlMessage()
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .picker)
        XCTAssert(obj.data.richControl?.uiType == "Picker")
        XCTAssert(obj.data.richControl?.model?.type == "field")
        XCTAssert(obj.data.richControl?.uiMetadata?.label == "What is the urgency: low, medium or high?")
        XCTAssert(obj.data.richControl?.uiMetadata?.required == true)
        XCTAssert(obj.data.richControl?.uiMetadata?.itemType == "ID")
        XCTAssert(obj.data.richControl?.uiMetadata?.style == "list")
        XCTAssert(obj.data.richControl?.uiMetadata?.multiSelect == false)
    }
    
    func testOutputTextMessageExample() {
        let textObj = ExampleData.exampleOutputTextControlMessage()
        XCTAssertNotNil(textObj)
        XCTAssertEqual(textObj.controlType, .text)
        XCTAssertEqual(textObj.data.richControl?.uiType, "OutputText")
        XCTAssertEqual(textObj.data.richControl?.model?.type, "outputMsg")
        XCTAssertEqual(textObj.data.richControl?.value, "Glad I could assist you.")
    }
    
    func testContextualActionMessageExample() {
        let contextualAction = ExampleData.exampleContextualActionMessage()
        XCTAssertNotNil(contextualAction)
        XCTAssertEqual(contextualAction.controlType, .contextualAction)
        XCTAssertEqual(contextualAction.data.richControl?.uiType, "ContextualAction")
        XCTAssertEqual(contextualAction.data.richControl?.uiMetadata?.inputControls.count, 3)
        XCTAssertEqual(contextualAction.options.count, 3)
        XCTAssertEqual(contextualAction.options[0].value, "showTopic")
        XCTAssertEqual(contextualAction.options[1].value, "startTopic")
        XCTAssertEqual(contextualAction.options[2].value, "brb")
    }
    
    let jsonInitStart = """
        {
          "type" : "actionMessage",
          "data" : {
            "@class" : ".ActionMessageDto",
            "messageId" : "fd6cc69073320300d63a566a4cf6a727",
            "taskId" : "796cc69073320300d63a566a4cf6a725",
            "sessionId" : "b93c861073320300d63a566a4cf6a7f7",
            "conversationId" : "f16cc69073320300d63a566a4cf6a725",
            "actionMessage" : {
              "contextHandshake" : {
                "serverContextReq" : {
                  "location" : {
                    "updateFrequency" : "every minute",
                    "updateType" : "push"
                  },
                  "MobileAppVersion" : {
                    "updateFrequency" : "once",
                    "updateType" : "push"
                  },
                  "deviceTimeZone" : {
                    "updateFrequency" : "once",
                    "updateType" : "push"
                  },
                  "DeviceType" : {
                    "updateFrequency" : "once",
                    "updateType" : "push"
                  },
                  "permissionToUseCamera" : {
                    "updateFrequency" : "once",
                    "updateType" : "push"
                  },
                  "permissionToUsePhoto" : {
                    "updateFrequency" : "once",
                    "updateType" : "push"
                  },
                  "MobileOS" : {
                    "updateFrequency" : "once",
                    "updateType" : "push"
                  }
                },
                "vendorId" : "c2f0b8f187033200246ddd4c97cb0bb9"
              },
              "loginStage" : "Start",
              "type" : "Init",
              "systemActionName" : "init"
            },
            "links" : [

            ],
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0,
            "sendTime" : 1512067038216
          },
          "source" : "server"
        }
        """
    
    func testInitEventFromJSON() {
        
        let obj = ChatDataFactory.actionFromJSON(jsonInitStart)
        XCTAssertNotNil(obj)
        XCTAssert(obj.eventType == .channelInit)
        
        let initObj = obj as? InitMessage
        XCTAssert(initObj != nil)
        XCTAssert(initObj?.data.actionMessage.systemActionName == "init")
        XCTAssert(initObj?.data.actionMessage.loginStage == .loginStart)
        XCTAssert(initObj?.data.actionMessage.contextHandshake.serverContextRequest?.count == 7)
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
        let topicPicker = SystemTopicPickerMessage(forSession: "1", withValue: "system")
        
        do {
            let jsonData = try encoder!.encode(topicPicker)
            let jsonString: String = String(data: jsonData, encoding: .utf8)!
            Logger.default.logInfo(jsonString)
            
            XCTAssert(jsonString.contains("\"type\":\"consumerTextMessage\""))
            XCTAssert(jsonString.contains("\"type\":\"topic\""))
            XCTAssert(jsonString.contains("\"uiType\":\"TopicPicker\""))
            XCTAssert(jsonString.contains("\"value\":\"system\""))
            
            let clone = try decoder!.decode(SystemTopicPickerMessage.self, from: jsonData)
            let cloneData = try encoder!.encode(clone)
            let cloneString = String(data: cloneData, encoding: .utf8)
            XCTAssertEqual(cloneString, jsonString)
        } catch let error {
            Logger.default.logInfo(error.localizedDescription)
        }
    }
    
    func testSystemErrorMessage() {
        let json = """
        {
          "type" : "systemTextMessage",
          "data" : {
            "@class" : ".MessageDto",
            "messageId" : "d5b33f3073320300d63a566a4cf6a74d",
            "richControl" : {
              "uiType" : "SystemError",
              "uiMetadata" : {
                "error" : {
                  "handler" : {
                    "type" : "Hmode",
                    "instruction" : "This conversation has been transferred to the Live Agent queue, and someone will be with you momentarily."
                  },
                  "message" : "An unrecoverable error has occurred.",
                  "code" : "system_error"
                }
              }
            },
            "taskId" : "ccb33f3073320300d63a566a4cf6a715",
            "sessionId" : "88a3f33073320300d63a566a4cf6a724",
            "conversationId" : "48b33f3073320300d63a566a4cf6a715",
            "links" : [

            ],
            "sendTime" : 1512074803616,
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0
          },
          "source" : "server"
        }
        """
        let jsonData = json.data(using: .utf8)
        let decoder = JSONDecoder()
        do {
            let systemMessage = try decoder.decode(ControlMessage<Any?, UIMetadata>.self, from: jsonData!) as ControlMessage
            XCTAssert(systemMessage.data.richControl?.uiType == "SystemError")
            XCTAssert(systemMessage.data.richControl?.uiMetadata?.error?.message == "An unrecoverable error has occurred.")
        } catch let error {
            Logger.default.logInfo(error.localizedDescription)
            XCTAssert(false)
        }
        
    }
    
    func testStartTopic() {
        do {
            let startTopic = StartTopicMessage(withSessionId: "session_id", withConversationId: "conversation_id")
            let jsonData = try CBData.jsonEncoder.encode(startTopic)
            let jsonString: String = String(data: jsonData, encoding: .utf8)!
            Logger.default.logInfo(jsonString)
            
            XCTAssert(jsonString.contains("\"type\":\"consumerTextMessage\""))
            XCTAssert(jsonString.contains("\"type\":\"task\""))
            XCTAssert(jsonString.contains("\"uiType\":\"ContextualAction\""))
            XCTAssert(jsonString.contains("\"value\":\"startTopic\""))
        } catch let err {
            Logger.default.logError(err.localizedDescription)
        }
    }
}
