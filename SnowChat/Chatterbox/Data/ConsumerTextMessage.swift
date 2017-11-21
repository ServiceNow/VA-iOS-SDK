//
//  ConsumerTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ConsumerTextMessage: Codable {
    let type: String
    let data: TextMessageData
    
    struct TextMessageData: Codable {
        let messageId: String
        let sessionId: Int
        let sendTime: Date
        let receiveTime: Date
        
        let richControl: ControlWrapper
        
        init(sessionId: Int, uiType: String, model: String, value: String) {
            self.messageId = UUID().uuidString
            self.sessionId = sessionId
            self.sendTime = Date()
            self.receiveTime = self.sendTime
            self.richControl = ControlWrapper(uiType: uiType, model: ControlModel(type: model), value: value)
        }
    }
    
    struct ControlWrapper: Codable {
        let uiType: String
        let model: ControlModel
        let value: String
    }
    
    struct ControlModel: Codable {
        let type: String
    }
    
    init(withData: TextMessageData) {
        type = "consumerTextMessage"
        data = withData
    }
}
