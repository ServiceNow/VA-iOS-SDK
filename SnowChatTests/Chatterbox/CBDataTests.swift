//
//  CBDataTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class TestControlData: ControlData {
    var direction: MessageDirection { return .fromClient }
    var uniqueId: String { return id }
    
    var messageId: String
    var conversationId: String?
    var messageTime: Date
    
    let id: String
    let controlType: ChatterboxControlType
    
    init() {
        id = "123"
        controlType = .unknown
        messageId = ChatUtil.uuidString()
        messageTime = Date()
    }
}

class ChatterboxDataTests: XCTestCase {
    
    var encoder: JSONEncoder?
    var decoder: JSONDecoder?
    
    override func setUp() {
        super.setUp()

        encoder = ChatUtil.jsonEncoder
        decoder = ChatUtil.jsonDecoder
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
        let inputObj = obj as? ControlDataUnknown
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
        XCTAssert(obj.data.richControl?.uiMetadata?.style == .list)
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
        XCTAssertEqual(contextualAction.data.richControl?.uiMetadata?.inputControls?.count, 3)
        XCTAssertEqual(contextualAction.options.count, 3)
        XCTAssertEqual(contextualAction.options[0].value, "showTopic")
        XCTAssertEqual(contextualAction.options[1].value, "startTopic")
        XCTAssertEqual(contextualAction.options[2].value, "brb")
    }
    
    func testSystemErrorMessageExample() {
        let systemError = ExampleData.exampleSystemErrorControlMessage()
        
        XCTAssertNotNil(systemError)
        XCTAssertEqual(systemError.controlType, .systemError)
        XCTAssertEqual(systemError.data.richControl?.uiType, "SystemError")
        XCTAssertEqual(systemError.data.richControl?.uiMetadata?.error.message, "An unrecoverable error has occurred.")
        XCTAssertEqual(systemError.data.richControl?.uiMetadata?.error.handler?.type, "Hmode")
        XCTAssertEqual(systemError.data.richControl?.uiMetadata?.error.handler?.instruction, "This conversation has been transferred to the Live Agent queue, and someone will be with you momentarily.")
    }
    
    func testAgentTextExample() {
        let agentText = ExampleData.exampleAgentTextControlMessage()
        
        XCTAssertNotNil(agentText)
        XCTAssertEqual("c012b7e3c31013009cbbdccdf3d3ae1e", agentText.messageId)
        XCTAssertEqual(agentText.controlType, .agentText)
        XCTAssertEqual(agentText.data.text, "Duty Now For The Future!")
        XCTAssertEqual(agentText.data.agent, true)
        XCTAssertEqual(agentText.data.isAgent, true)
        XCTAssertEqual(agentText.data.sender?.name, "Beth Anglin")
    }
    
    func testCancelTopicMessageExample() {
        let cancelTopic = ExampleData.exampleCancelTopicMessage()
        
        XCTAssertEqual(ChatterboxActionType.cancelUserTopic, cancelTopic.eventType)
        XCTAssertEqual("actionMessage", cancelTopic.type)
        XCTAssertEqual("CancelTopic", cancelTopic.data.actionMessage.type)
        XCTAssertEqual("cancelVendorTopic", cancelTopic.data.actionMessage.systemActionName)
        XCTAssertEqual(true, cancelTopic.data.actionMessage.ready)
    }
    
    func testCancelTopicRequestExample() {
        let cancelRequestMessage = ExampleData.exampleCancelTopicControlMessage()
        
        XCTAssertEqual(ChatterboxControlType.cancelTopic, cancelRequestMessage.controlType)
        XCTAssertEqual("cancelTopic", (cancelRequestMessage.data.richControl?.value)!)
        XCTAssertEqual("task", cancelRequestMessage.data.richControl?.model?.type)
        XCTAssertEqual("ContextualAction", cancelRequestMessage.data.richControl?.uiType)
    }
    
    func testSubscribeToSupportQueueExample() {
        let message = ExampleData.exampleSubscribeToSupportQueueMessage()
        XCTAssertEqual(ChatterboxActionType.supportQueueSubscribe, message.eventType)
        XCTAssertEqual("/cs/support_queue/c3lzX2lkPWY0ZDcwMWIxYjM5MDAzMDBmN2QxYTEzODE2YThkYzhl", message.channel)
        XCTAssertEqual("actionMessage", message.type)
        XCTAssertEqual("SubscribeToSupportQueue", message.data.actionMessage.type)
        XCTAssertEqual(true, message.active)
        XCTAssertEqual("30 Seconds", message.waitTimeDisplayString)
        XCTAssertTrue(message.data.actionMessage.supportQueue.sysId!.lengthOfBytes(using: String.Encoding.utf8) > 0)
    }

    func testSupportQueueUpdateExample() {
        let message = ExampleData.exampleSupportQueueUpdateMessage()!
        XCTAssertEqual(nil, message.channel)
        XCTAssertEqual(true, message.active)
        XCTAssertEqual("30 Seconds", message.averageWaitTime)
        XCTAssertNil(message.sysId)
    }

    func testEndAgentChatExample() {
        let message = ExampleData.exampleEndAgentChatMessage()
        XCTAssertEqual(ChatterboxActionType.endAgentChat, message.eventType)
        XCTAssertEqual("actionMessage", message.type)
        XCTAssertEqual("endChat", message.data.actionMessage.systemActionName)
        XCTAssertEqual("EndChat", message.data.actionMessage.type)
        XCTAssertTrue(message.data.actionMessage.topicId.lengthOfBytes(using: .utf8) > 0)
    }
    
    func testShowTopicMessage() {
        let message = ExampleData.exampleShowTopicResponseMessage()
        XCTAssertEqual(ChatterboxActionType.showTopic, message.eventType)
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
    
    func testStartTopic() {
        do {
            let startTopic = StartTopicMessage(withSessionId: "session_id", withConversationId: "conversation_id")
            let jsonData = try ChatUtil.jsonEncoder.encode(startTopic)
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
