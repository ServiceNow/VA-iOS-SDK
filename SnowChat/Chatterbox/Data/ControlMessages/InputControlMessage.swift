//
//  InputControlMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct InputControlMessage: Codable, CBControlData {
    
    func uniqueId() -> String {
        return id
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .input
    
    let type: String = "consumerTextMessage"
    var data: RichControlData<ControlWrapper<String?, UIMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String?, UIMetadata>>) {
        data = withData
    }
    
    init(withValue value: String, fromMessage message: InputControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
    
    internal static func exampleInstance() -> InputControlMessage {
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
        return CBDataFactory.controlFromJSON(jsonInputText) as! InputControlMessage
    }
}
