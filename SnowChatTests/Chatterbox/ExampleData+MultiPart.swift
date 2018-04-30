//
//  ExampleData+MultiPart.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 4/30/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

@testable import SnowChat

extension ExampleData {
    
    static func multiPartHtmlControlMessage() -> MultiPartControlMessage {
        let jsonMultiPart = """
        {
            "type": "consumerTextMessage",
            "data": {
                "messageId": "177A862D06194E218FC13A2156E4DF29",
                "richControl": {
                    "model": {
                        "name": "fieldAck.__silent_MultiPartOutputPrompt_08c84a11821b4f3cbafac4cf96c3a352",
                        "type": "outputMsg"
                    },
                    "content": {
                        "value": "<html>     <body>          <!-- enter your markup here here -->     <h1>stuff</h1>     </body> </html> ",
                        "uiType": "OutputHtml",
                        "uiMetadata": {
                            "width": 0,
                            "type": "html",
                            "height": 0
                        }
                    },
                    "uiType": "MultiPartOutput",
                    "uiMetadata": {
                        "index": 4,
                        "navigationBtnLabel": "more"
                    }
                },
                "taskId": "726a2821dbfd1300f7f29cb8db9619ca",
                "sessionId": "7b88acaddbbd1300f7f29cb8db9619a1",
                "conversationId": "7e6a2821dbfd1300f7f29cb8db9619c9",
                "sendTime": 1525108708782,
                "direction": "inbound",
                "isAgent": false,
                "receiveTime": 0
            }
        }
        """
        return ChatDataFactory.controlFromJSON(jsonMultiPart) as! MultiPartControlMessage
    }
    
    static func multiPartOutputTextControlMessage() -> MultiPartControlMessage {
        let jsonMultiPart = """
        {
            "data": {
                "richControl": {
                    "model": {
                        "name": "fieldAck.__silent_MultiPartOutputPrompt_08c84a11821b4f3cbafac4cf96c3a352",
                        "type": "outputMsg"
                    },
                    "content": {
                        "value": "thing 1",
                        "uiType": "OutputText"
                    },
                    "uiType": "MultiPartOutput",
                    "uiMetadata": {
                        "index": 0,
                        "navigationBtnLabel": "more"
                    }
                },
                "@class": ".MessageDto",
                "messageId": "a2e37869dbfd1300416e769e0f96190b",
                "sendTime": 1525110754516,
                "conversationId": "16e37869dbfd1300416e769e0f961906",
                "receiveTime": 0,
                "links": [

                ],
                "sessionId": "32d3f469dbfd1300416e769e0f9619d2",
                "hidden": false,
                "taskId": "1ae37869dbfd1300416e769e0f961906",
                "sequence": "16317af4cd50000001",
                "isAgent": false,
                "direction": "outbound"
            },
            "source": "server",
            "type": "systemTextMessage",
            "sent_by": 5361929
        }
        """
        return ChatDataFactory.controlFromJSON(jsonMultiPart) as! MultiPartControlMessage
    }
    
    static func multiPartOutputImageControlMessage() -> MultiPartControlMessage {
        let jsonMultiPart = """
        {
            "type": "consumerTextMessage",
            "data": {
                "messageId": "177A862D06194E218FC13A2156E4DF29",
                "richControl": {
                    "model": {
                        "name": "fieldAck.__silent_MultiPartOutputPrompt_08c84a11821b4f3cbafac4cf96c3a352",
                        "type": "outputMsg"
                    },
                    "content": {
                        "value": "<html>     <body>          <!-- enter your markup here here -->     <h1>stuff</h1>     </body> </html> ",
                        "uiType": "OutputHtml",
                        "uiMetadata": {
                            "width": 0,
                            "type": "html",
                            "height": 0
                        }
                    },
                    "uiType": "MultiPartOutput",
                    "uiMetadata": {
                        "index": 4,
                        "navigationBtnLabel": "more"
                    }
                },
                "taskId": "726a2821dbfd1300f7f29cb8db9619ca",
                "sessionId": "7b88acaddbbd1300f7f29cb8db9619a1",
                "conversationId": "7e6a2821dbfd1300f7f29cb8db9619c9",
                "sendTime": 1525108708782,
                "direction": "inbound",
                "isAgent": false,
                "receiveTime": 0
            }
        }
        """
        return ChatDataFactory.controlFromJSON(jsonMultiPart) as! MultiPartControlMessage
    }
    
    static func multiPartOutputLinkControlMessage() -> MultiPartControlMessage {
        let jsonMultiPart = """
        {
            "type": "consumerTextMessage",
            "data": {
                "messageId": "177A862D06194E218FC13A2156E4DF29",
                "richControl": {
                    "model": {
                        "name": "fieldAck.__silent_MultiPartOutputPrompt_08c84a11821b4f3cbafac4cf96c3a352",
                        "type": "outputMsg"
                    },
                    "content": {
                        "value": "<html>     <body>          <!-- enter your markup here here -->     <h1>stuff</h1>     </body> </html> ",
                        "uiType": "OutputHtml",
                        "uiMetadata": {
                            "width": 0,
                            "type": "html",
                            "height": 0
                        }
                    },
                    "uiType": "MultiPartOutput",
                    "uiMetadata": {
                        "index": 4,
                        "navigationBtnLabel": "more"
                    }
                },
                "taskId": "726a2821dbfd1300f7f29cb8db9619ca",
                "sessionId": "7b88acaddbbd1300f7f29cb8db9619a1",
                "conversationId": "7e6a2821dbfd1300f7f29cb8db9619c9",
                "sendTime": 1525108708782,
                "direction": "inbound",
                "isAgent": false,
                "receiveTime": 0
            }
        }
        """
        return ChatDataFactory.controlFromJSON(jsonMultiPart) as! MultiPartControlMessage
    }
}
