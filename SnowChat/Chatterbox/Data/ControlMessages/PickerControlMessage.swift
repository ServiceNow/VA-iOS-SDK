//
//  PickerControlMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct PickerControlMessage: Codable, CBControlData {
    
    func uniqueId() -> String {
        return id
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .picker
    
    let type: String = "consumerTextMessage"
    var data: RichControlData<ControlWrapper<String?, PickerMetadata>>
    
    struct PickerMetadata: Codable {
        let multiSelect: Bool
        let style: String
        let openByDefault: Bool
        let required: Bool
        let itemType: String
        let label: String
        let options: [LabeledValue]
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String?, PickerMetadata>>) {
        data = withData
    }
    
    init(withValue value: String, fromMessage message: PickerControlMessage) {
        data = message.data
        data.sendTime = Date()
        data.richControl?.value = value
    }
    
    // swiftlint:disable:next function_body_length
    internal static func exampleInstance() -> PickerControlMessage {
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
        return CBDataFactory.controlFromJSON(jsonPicker) as! PickerControlMessage
    }
}
