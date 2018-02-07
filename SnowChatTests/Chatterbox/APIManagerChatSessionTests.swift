//
//  APIManagerChatSessionTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 1/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest

@testable import SnowChat

class APIManagerChatSessionTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testConversationResultParsing() throws {
        let jsonData = conversationResultJSON.data(using: .utf8)
        let resultsDictionary = try JSONSerialization.jsonObject(with: jsonData!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
        let conversationDictionary = resultsDictionary["conversation"]
        let parsedResults = APIManager.conversationsFromResult([conversationDictionary], assumeMessagesReversed: false)
        
        XCTAssert(parsedResults.count == 1)
        let conversation = parsedResults[0]
        
        XCTAssertEqual("139dd4f673234300d63a566a4cf6a7c6", conversation.conversationId)
        XCTAssertEqual(Conversation.ConversationState.completed, conversation.state)
        XCTAssertEqual(4, conversation.messageExchanges().count)
        
        var exchangesInOrder: [MessageExchange] = conversation.messageExchanges()
        
        var exchange = exchangesInOrder[0]
        let booleanMessage: BooleanControlMessage = exchange.message as! BooleanControlMessage
        let booleanResponse: BooleanControlMessage = exchange.response as! BooleanControlMessage
        XCTAssert(booleanMessage.data.direction == .fromServer)
        XCTAssert(booleanResponse.data.direction == .fromClient)
        XCTAssertEqual("1", booleanMessage.data.messageId)
        XCTAssertEqual("2", booleanResponse.data.messageId)
        
        exchange = exchangesInOrder[1]
        let inputMessage: InputControlMessage = exchange.message as! InputControlMessage
        let inputResponse: InputControlMessage = exchange.response as! InputControlMessage
        XCTAssert(inputMessage.data.direction == .fromServer)
        XCTAssert(inputResponse.data.direction == .fromClient)
        XCTAssertEqual("3", inputMessage.data.messageId)
        XCTAssertEqual("4", inputResponse.data.messageId)
    }
    
    func testConversationsResultParsing() throws {
        let jsonData = conversationsResultJSON.data(using: .utf8)
        let resultsDictionary = try JSONSerialization.jsonObject(with: jsonData!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
        let conversations = resultsDictionary["conversations"]
        
        let parsedResults = APIManager.conversationsFromResult(conversations!, assumeMessagesReversed: false)

        XCTAssert(parsedResults.count == 1)
        let conversation = parsedResults[0]

        XCTAssertEqual("139dd4f673234300d63a566a4cf6a7c6", conversation.conversationId)
        XCTAssertEqual(Conversation.ConversationState.completed, conversation.state)
        XCTAssertEqual(4, conversation.messageExchanges().count)
        
        var exchange = conversation.messageExchanges()[0]
        let booleanMessage = exchange.message as! BooleanControlMessage
        let booleanResponse = exchange.response as! BooleanControlMessage
        XCTAssert(booleanMessage.data.direction == .fromServer)
        XCTAssert(booleanResponse.data.direction == .fromClient)
        XCTAssertEqual("1", booleanMessage.data.messageId)
        XCTAssertEqual("2", booleanResponse.data.messageId)
        XCTAssertTrue(exchange.isComplete)
        
        exchange = conversation.messageExchanges()[1]
        let inputMessage = exchange.message as! InputControlMessage
        let inputResponse = exchange.response as! InputControlMessage
        XCTAssert(inputMessage.data.direction == .fromServer)
        XCTAssert(inputResponse.data.direction == .fromClient)
        XCTAssertEqual("3", inputMessage.data.messageId)
        XCTAssertEqual("4", inputResponse.data.messageId)
        XCTAssertEqual("Door is not unlocking", inputResponse.data.richControl?.value!)
        XCTAssertTrue(exchange.isComplete)
        
        exchange = conversation.messageExchanges()[2]
        let pickerMessage = exchange.message as! PickerControlMessage
        let pickerResponse = exchange.response as! PickerControlMessage
        XCTAssert(inputMessage.data.direction == .fromServer)
        XCTAssert(inputResponse.data.direction == .fromClient)
        XCTAssertEqual("5", pickerMessage.data.messageId)
        XCTAssertEqual("6", pickerResponse.data.messageId)
        XCTAssertEqual("2", pickerResponse.data.richControl?.value!)
        XCTAssertTrue(exchange.isComplete)
        
        exchange = conversation.messageExchanges()[3]
        let textOutput = exchange.message as! OutputTextControlMessage
        XCTAssertEqual(.fromServer, textOutput.data.direction)
        XCTAssertEqual("7", textOutput.data.messageId)
        XCTAssertEqual("INC0010051 has been created for you. Glad I could assist you.", textOutput.data.richControl?.value!)
        XCTAssertTrue(exchange.isComplete)
    }
    
    let conversationResultJSON = """
        {
            "responseId": null,
            "responseTime": 0,
            "requestId": null,
            "session": null,
            "conversation": {
                "messages": [
                    {
                        "@class": ".MessageDto",
                        "messageId": "1",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "outbound",
                        "sendTime": 1515776777000,
                        "receiveTime": 0,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "Boolean",
                            "model": {
                                "type": "field",
                                "name": "init_create_incident"
                            },
                            "uiMetadata": {
                                "label": "Would you like to create an incident?",
                                "required": true
                            }
                        },
                        "isAgent": false
                    },
                    {
                        "@class": ".MessageDto",
                        "messageId": "2",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "inbound",
                        "sendTime": 1515776780000,
                        "receiveTime": 1515776780000,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "Boolean",
                            "model": {
                                "type": "field",
                                "name": "init_create_incident"
                            },
                            "uiMetadata": {
                                "label": "Would you like to create an incident?",
                                "required": true
                            },
                            "value": true
                        },
                        "isAgent": false
                    },
                    {
                        "@class": ".MessageDto",
                        "messageId": "3",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "outbound",
                        "sendTime": 1515776780000,
                        "receiveTime": 0,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "InputText",
                            "model": {
                                "type": "field",
                                "name": "short_description"
                            },
                            "uiMetadata": {
                                "label": "Please enter a short description of the issue you would like to report.",
                                "required": true
                            }
                        },
                        "isAgent": false
                    },
                    {
                        "@class": ".MessageDto",
                        "messageId": "4",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "inbound",
                        "sendTime": 1515776789000,
                        "receiveTime": 1515776789000,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "InputText",
                            "model": {
                                "type": "field",
                                "name": "short_description"
                            },
                            "uiMetadata": {
                                "label": "Please enter a short description of the issue you would like to report.",
                                "required": true
                            },
                            "value": "Door is not unlocking"
                        },
                        "isAgent": false
                    },
                    {
                        "@class": ".MessageDto",
                        "messageId": "5",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "outbound",
                        "sendTime": 1515776789000,
                        "receiveTime": 0,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "Picker",
                            "model": {
                                "type": "field",
                                "name": "urgency"
                            },
                            "uiMetadata": {
                                "label": "What is the urgency: low, medium or high?",
                                "itemType": "ID",
                                "style": "list",
                                "options": [
                                    {
                                        "label": "High",
                                        "value": "1"
                                    },
                                    {
                                        "label": "Medium",
                                        "value": "2"
                                    },
                                    {
                                        "label": "Low",
                                        "value": "3"
                                    }
                                ],
                                "multiSelect": false,
                                "openByDefault": true,
                                "required": true
                            }
                        },
                        "isAgent": false
                    },
                    
                    {
                        "@class": ".MessageDto",
                        "messageId": "6",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "inbound",
                        "sendTime": 1515776791000,
                        "receiveTime": 1515776791000,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "Picker",
                            "model": {
                                "type": "field",
                                "name": "urgency"
                            },
                            "uiMetadata": {
                                "label": "What is the urgency: low, medium or high?",
                                "itemType": "ID",
                                "style": "list",
                                "options": [
                                    {
                                        "label": "High",
                                        "value": "1"
                                    },
                                    {
                                        "label": "Medium",
                                        "value": "2"
                                    },
                                    {
                                        "label": "Low",
                                        "value": "3"
                                    }
                                ],
                                "multiSelect": false,
                                "openByDefault": true,
                                "required": true
                            },
                            "value": "2"
                        },
                        "isAgent": false
                    },
                    {
                        "@class": ".MessageDto",
                        "messageId": "7",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "taskId": "179dd4f673234300d63a566a4cf6a7c6",
                        "direction": "outbound",
                        "sendTime": 1515776792000,
                        "receiveTime": 0,
                        "links": [

                        ],
                        "richControl": {
                            "uiType": "OutputText",
                            "model": {
                                "type": "outputMsg",
                                "name": "fieldAck.__silent_sys_cb_prompt_4d39c403b370030001182ab716a8dc5a"
                            },
                            "value": "INC0010051 has been created for you. Glad I could assist you."
                        },
                        "isAgent": false
                    },
                    {
                        "@class": "com.glide.cs.qlue.actions.systemAction.ActionMessageDto",
                        "messageId": "8",
                        "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
                        "direction": "outbound",
                        "sendTime": 1515776792000,
                        "receiveTime": 0,
                        "links": [

                        ],
                        "isAgent": false,
                        "actionMessage": {
                            "type": "TopicFinished",
                            "systemActionName": "TopicFinished"
                        }
                    }
                ],
                "consumerAcctId": "c29d18f673234300d63a566a4cf6a71a",
                "consumerId": "429d18f673234300d63a566a4cf6a71a",
                "title": "Create Incident-139dd4f673234300d63a566a",
                "createdAt": 1515776777000,
                "updatedAt": 1515776792000,
                "deviceId": "6CCF1FC8-732E-44E7-AD25-64E5E4F8F098",
                "vendorId": "c2f0b8f187033200246ddd4c97cb0bb9",
                "status": "COMPLETED",
                "deviceType": "ios",
                "topicTypeName": "Create Incident",
                "topicId": "139dd4f673234300d63a566a4cf6a7c6"
            },
            "task": null,
            "message": null,
            "replyMessage": null
        }
    """
    
    let conversationsResultJSON = """
    {
      "responseId": "f4c3d335-8443-4fca-bec4-e3bb6484195f",
      "responseTime": 1515776844091,
      "unreadMessageCount": 15,
      "conversations": [
        {
          "messages": [
            {
              "@class": ".MessageDto",
              "messageId": "1",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "outbound",
              "sendTime": 1515776777000,
              "receiveTime": 0,
              "links": [],
              "richControl": {
                "uiType": "Boolean",
                "model": {
                  "type": "field",
                  "name": "init_create_incident"
                },
                "uiMetadata": {
                  "label": "Would you like to create an incident?",
                  "required": true
                }
              },
              "isAgent": false
            },
            {
              "@class": ".MessageDto",
              "messageId": "2",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "inbound",
              "sendTime": 1515776780000,
              "receiveTime": 1515776780000,
              "links": [],
              "richControl": {
                "uiType": "Boolean",
                "model": {
                  "type": "field",
                  "name": "init_create_incident"
                },
                "uiMetadata": {
                  "label": "Would you like to create an incident?",
                  "required": true
                },
                "value": true
              },
              "isAgent": false
            },
            {
              "@class": ".MessageDto",
              "messageId": "3",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "outbound",
              "sendTime": 1515776780000,
              "receiveTime": 0,
              "links": [],
              "richControl": {
                "uiType": "InputText",
                "model": {
                  "type": "field",
                  "name": "short_description"
                },
                "uiMetadata": {
                  "label": "Please enter a short description of the issue you would like to report.",
                  "required": true
                }
              },
              "isAgent": false
            },
            {
              "@class": ".MessageDto",
              "messageId": "4",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "inbound",
              "sendTime": 1515776789000,
              "receiveTime": 1515776789000,
              "links": [],
              "richControl": {
                "uiType": "InputText",
                "model": {
                  "type": "field",
                  "name": "short_description"
                },
                "uiMetadata": {
                  "label": "Please enter a short description of the issue you would like to report.",
                  "required": true
                },
                "value": "Door is not unlocking"
              },
              "isAgent": false
            },
            {
              "@class": ".MessageDto",
              "messageId": "5",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "outbound",
              "sendTime": 1515776789000,
              "receiveTime": 0,
              "links": [],
              "richControl": {
                "uiType": "Picker",
                "model": {
                  "type": "field",
                  "name": "urgency"
                },
                "uiMetadata": {
                  "label": "What is the urgency: low, medium or high?",
                  "itemType": "ID",
                  "style": "list",
                  "options": [
                    {
                      "label": "High",
                      "value": "1"
                    },
                    {
                      "label": "Medium",
                      "value": "2"
                    },
                    {
                      "label": "Low",
                      "value": "3"
                    }
                  ],
                  "multiSelect": false,
                  "openByDefault": true,
                  "required": true
                }
              },
              "isAgent": false
            },
            {
              "@class": ".MessageDto",
              "messageId": "6",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "inbound",
              "sendTime": 1515776791000,
              "receiveTime": 1515776791000,
              "links": [],
              "richControl": {
                "uiType": "Picker",
                "model": {
                  "type": "field",
                  "name": "urgency"
                },
                "uiMetadata": {
                  "label": "What is the urgency: low, medium or high?",
                  "itemType": "ID",
                  "style": "list",
                  "options": [
                    {
                      "label": "High",
                      "value": "1"
                    },
                    {
                      "label": "Medium",
                      "value": "2"
                    },
                    {
                      "label": "Low",
                      "value": "3"
                    }
                  ],
                  "multiSelect": false,
                  "openByDefault": true,
                  "required": true
                },
                "value": "2"
              },
              "isAgent": false
            },
            {
              "@class": ".MessageDto",
              "messageId": "7",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "taskId": "179dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "outbound",
              "sendTime": 1515776792000,
              "receiveTime": 0,
              "links": [],
              "richControl": {
                "uiType": "OutputText",
                "model": {
                  "type": "outputMsg",
                  "name": "fieldAck.__silent_sys_cb_prompt_4d39c403b370030001182ab716a8dc5a"
                },
                "value": "INC0010051 has been created for you. Glad I could assist you."
              },
              "isAgent": false
            },
            {
              "@class": "com.glide.cs.qlue.actions.systemAction.ActionMessageDto",
              "messageId": "8",
              "conversationId": "139dd4f673234300d63a566a4cf6a7c6",
              "consumerAccountId": "c29d18f673234300d63a566a4cf6a71a",
              "direction": "outbound",
              "sendTime": 1515776792000,
              "receiveTime": 0,
              "links": [],
              "isAgent": false,
              "actionMessage": {
                "type": "TopicFinished",
                "systemActionName": "TopicFinished"
              }
            }
          ],
          "consumerAcctId": "c29d18f673234300d63a566a4cf6a71a",
          "consumerId": "429d18f673234300d63a566a4cf6a71a",
          "unreadMessageCount": 8,
          "title": "Create Incident-139dd4f673234300d63a566a",
          "createdAt": 1515776777000,
          "updatedAt": 1515776792000,
          "deviceId": "6CCF1FC8-732E-44E7-AD25-64E5E4F8F098",
          "vendorId": "c2f0b8f187033200246ddd4c97cb0bb9",
          "status": "COMPLETED",
          "deviceType": "ios",
          "topicTypeName": "Create Incident",
          "topicId": "139dd4f673234300d63a566a4cf6a7c6"
        }
      ]
    }
    """
}
