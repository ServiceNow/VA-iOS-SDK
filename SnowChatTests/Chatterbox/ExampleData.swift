//
//  ExampleData.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 1/23/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
@testable import SnowChat

class ExampleData {
    
    static func exampleBooleanControlMessage() -> BooleanControlMessage {
        let jsonBoolean = """
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
        return ChatDataFactory.controlFromJSON(jsonBoolean) as! BooleanControlMessage
    }
    
    static func exampleInputControlMessage() -> InputControlMessage {
        let jsonInputText = """
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
        return ChatDataFactory.controlFromJSON(jsonInputText) as! InputControlMessage
    }
    
    // swiftlint:disable:next function_body_length
    static func examplePickerControlMessage() -> PickerControlMessage {
        let jsonPicker = """
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
        return ChatDataFactory.controlFromJSON(jsonPicker) as! PickerControlMessage
    }
    
    static func exampleOutputTextControlMessage() -> OutputTextControlMessage {
        let jsonOutputText = """
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
        return ChatDataFactory.controlFromJSON(jsonOutputText) as! OutputTextControlMessage
    }
    
    static func exampleContextualActionMessage() -> ContextualActionMessage {
        let jsonContextualAction = """
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
        return ChatDataFactory.controlFromJSON(jsonContextualAction) as! ContextualActionMessage
    }
    
    static func exampleSystemErrorControlMessage() -> SystemErrorControlMessage {
        let jsonSystemErrorMessage = """
        {
            "type": "systemTextMessage",
            "data": {
                "@class": ".MessageDto",
                "messageId": "08dccafd13ab0300e283b90a6144b061",
                "richControl": {
                    "uiType": "SystemError",
                    "uiMetadata": {
                        "error": {
                            "handler": {
                                "type": "Hmode",
                                "instruction": "This conversation has been transferred to the Live Agent queue, and someone will be with you momentarily."
                            },
                            "message": "An unrecoverable error has occurred.",
                            "code": "system_error"
                        }
                    }
                },
                "taskId": "82cc8e7d13ab0300e283b90a6144b07d",
                "sessionId": "f0cc8ebd13ab0300e283b90a6144b0d5",
                "conversationId": "8ecc8e7d13ab0300e283b90a6144b07c",
                "links": [

                ],
                "sendTime": 1515537492048,
                "direction": "outbound",
                "isAgent": false,
                "receiveTime": 0
            },
            "source": "server"
        }
        """
        return ChatDataFactory.controlFromJSON(jsonSystemErrorMessage) as! SystemErrorControlMessage
    }
}
