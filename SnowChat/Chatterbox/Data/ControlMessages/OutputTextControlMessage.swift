//
//  OutputTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/8/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct OutputTextControlMessage: Codable, CBControlData {
    func uniqueId() -> String {
        return id
    }
    
    var id: String = CBData.uuidString()
    var controlType: CBControlType = .text
    
    let type: String = "SystemTextMessage"
    var data: RichControlData<ControlWrapper<String, UIMetadata>>
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(withData: RichControlData<ControlWrapper<String, UIMetadata>>) {
        data = withData
    }
    
    internal static func exampleInstance() -> OutputTextControlMessage {
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
        return CBDataFactory.controlFromJSON(jsonOutputText) as! OutputTextControlMessage
    }
}
