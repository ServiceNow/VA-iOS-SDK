//
//  TextMessageData.swift
//  SnowChat
//
//  RichControlData represents the inner-data of a Chat message. Control messages use and extend this
//  for whatever unique fields they have to represent.
//
//  For example, the SystemTextMessage extends this by defining a struct
//        struct ControlWrapper: Codable {
//            let uiType: String = "Boolean"
//            let uiMetadata: UIMetadata
//            let model: ModelType
//        }
//
//  and then uses it like
//        struct SystemTextMessage: Codable {
//
//            let type: String
//            let data: RichControlData<ControlWrapper>
//          ...
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct RichControlData<T: Codable>: Codable {
    let messageId: String
    let sessionId: Int
    let sendTime: Date
    let receiveTime: Date
    
    let richControl: T
    
    init(sessionId: Int, controlData: T) {
        self.messageId = UUID().uuidString
        self.sessionId = sessionId
        self.sendTime = Date()
        self.receiveTime = self.sendTime
        self.richControl = controlData
    }
}

