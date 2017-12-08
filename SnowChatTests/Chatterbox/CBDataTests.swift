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
    func uniqueId() -> String {
        return id
    }
    
    let id: String
    let controlType: CBControlType
    
    init() {
        id = "123"
        controlType = .unknown
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
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .unknown)
        let inputObj = obj as? CBControlDataUnknown
        XCTAssertNotNil(inputObj)
    }

    func testBooleanFromJSON() {
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
              "value": true,
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
        XCTAssert(obj.controlType == .boolean)
        let boolObj = obj as! BooleanControlMessage
        XCTAssert(boolObj.data.richControl?.uiType == "Boolean")
        XCTAssert(boolObj.data.richControl?.model?.type == "field")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.label == "Would you like to create an incident?")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.required == true)
    }
    
    func testInputFromJSON() {
        let json = """
        {
          "type" : "systemTextMessage",
          "data" : {
            "@class" : ".MessageDto",
            "messageId" : "720ea46773760300d63a566a4cf6a743",
            "richControl" : {
              "model" : {
                "name" : "short_description",
                "type" : "field"
              },
              "uiType" : "InputText",
              "uiMetadata" : {
                "label" : "Please enter a short description of the issue you would like to report.",
                "required" : true
              }
            },
            "taskId" : "33fda46773760300d63a566a4cf6a74b",
            "sessionId" : "47fde42773760300d63a566a4cf6a73f",
            "conversationId" : "3ffda46773760300d63a566a4cf6a74a",
            "links" : [

            ],
            "sendTime" : 1512761185086,
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0
          },
          "source" : "server"
        }
        """
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .input)
        let boolObj = obj as! InputControlMessage
        XCTAssert(boolObj.data.richControl?.uiType == "InputText")
        XCTAssert(boolObj.data.richControl?.model?.type == "field")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.label == "Please enter a short description of the issue you would like to report.")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.required == true)
    }
    
    func testPickerFromJSON() {
        let json = """
        {
          "type" : "systemTextMessage",
          "data" : {
            "@class" : ".MessageDto",
            "messageId" : "d9f0c92b73760300d63a566a4cf6a717",
            "richControl" : {
              "model" : {
                "name" : "urgency",
                "type" : "field"
              },
              "uiType" : "Picker",
              "uiMetadata" : {
                "multiSelect" : false,
                "style" : "list",
                "openByDefault" : true,
                "label" : "What is the urgency: low, medium or high?",
                "options" : [
                  {
                    "label" : "High",
                    "value" : "1"
                  },
                  {
                    "label" : "Medium",
                    "value" : "2"
                  },
                  {
                    "label" : "Low",
                    "value" : "3"
                  }
                ],
                "required" : true,
                "itemType" : "ID"
              }
            },
            "taskId" : "efe0892b73760300d63a566a4cf6a7b9",
            "sessionId" : "47e0892b73760300d63a566a4cf6a79b",
            "conversationId" : "ebe0892b73760300d63a566a4cf6a7b9",
            "links" : [

            ],
            "sendTime" : 1512766143466,
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0
          },
          "source" : "server"
        }
        """
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .picker)
        let boolObj = obj as! PickerControlMessage
        XCTAssert(boolObj.data.richControl?.uiType == "Picker")
        XCTAssert(boolObj.data.richControl?.model?.type == "field")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.label == "What is the urgency: low, medium or high?")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.required == true)
        XCTAssert(boolObj.data.richControl?.uiMetadata?.itemType == "ID")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.style == "list")
        XCTAssert(boolObj.data.richControl?.uiMetadata?.multiSelect == false)
    }
    
    func testOutputTextMessage() {
        let json = """
        {
          "type" : "systemTextMessage",
          "data" : {
            "@class" : ".MessageDto",
            "messageId" : "1849dd2f73760300d63a566a4cf6a7f5",
            "richControl" : {
              "model" : {
                "name" : "fieldAck.__silent_sys_cb_prompt_9818cccfb330030001182ab716a8dc7f",
                "type" : "outputMsg"
              },
              "uiType" : "OutputText",
              "value" : "Glad I could assist you."
            },
            "taskId" : "6739dd2f73760300d63a566a4cf6a7cf",
            "sessionId" : "bf29dd2f73760300d63a566a4cf6a759",
            "conversationId" : "6339dd2f73760300d63a566a4cf6a7cf",
            "links" : [

            ],
            "sendTime" : 1512772512460,
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0
          },
          "source" : "server"
        }
        """
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj.controlType, .text)
        let textObj = obj as! OutputTextMessage
        XCTAssertEqual(textObj.data.richControl?.uiType, "OutputText")
        XCTAssertEqual(textObj.data.richControl?.model?.type, "outputMsg")
        XCTAssertEqual(textObj.data.richControl?.value, "Glad I could assist you.")
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
        
        let obj = CBDataFactory.channelEventFromJSON(jsonInitStart)
        XCTAssertNotNil(obj)
        XCTAssert(obj.eventType == .channelInit)
        
        let initObj = obj as? InitMessage
        XCTAssert(initObj != nil)
        XCTAssert(initObj?.data.actionMessage.systemActionName == "init")
        XCTAssert(initObj?.data.actionMessage.loginStage == "Start")
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
    
    func testContextualActionMessage() {
        
        let json = """
            {
            "type": "systemTextMessage",
            "data": {
                "@class": ".MessageDto",
                "messageId": "9807448173320300d63a566a4cf6a7ed",
                "richControl": {
                    "model": {
                        "type": "task"
                    },
                    "uiType": "ContextualAction",
                    "uiMetadata": {
                        "inputControls": [
                            {
                                "model": {
                                    "type": "task"
                                },
                                "uiType": "Picker",
                                "uiMetadata": {
                                    "options": [
                                        {
                                            "label": "Show Conversation",
                                            "value": "showTopic"
                                        },
                                        {
                                            "label": "Start a new conversation",
                                            "value": "startTopic"
                                        },
                                        {
                                            "label": "Chat with agent",
                                            "value": "brb"
                                        }
                                    ],
                                    "multiSelect": false,
                                    "openByDefault": false
                                }
                            },
                            {
                                "model": {
                                    "type": "task"
                                },
                                "uiType": "TextSearch"
                            },
                            {
                                "model": {
                                    "type": "task"
                                },
                                "uiType": "VoiceSearch"
                            }
                        ]
                    }
                },
                "sessionId": "eef6844173320300d63a566a4cf6a758",
                "conversationId": "5407c08173320300d63a566a4cf6a7f1",
                "links": [

                ],
                "sendTime": 1512079862721,
                "direction": "outbound",
                "isAgent": false,
                "receiveTime": 0
            },
            "source": "server"
        }
        """
        let jsonData = json.data(using: .utf8)
        let decoder = JSONDecoder()
        do {
            let systemMessage = try decoder.decode(ContextualActionMessage.self, from: jsonData!) as ContextualActionMessage
            XCTAssert(systemMessage.data.richControl?.uiType == "ContextualAction")
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
