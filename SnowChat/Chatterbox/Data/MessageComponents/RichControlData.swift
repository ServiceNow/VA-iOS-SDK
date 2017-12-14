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
    let sessionId: String
    var conversationId: String?
    var taskId: String?
    var direction: String
    var sendTime: Date
    var receiveTime: Date?

    var richControl: T?
    
    init(sessionId: String, conversationId: String?, controlData: T?) {
        self.messageId = CBData.uuidString()
        self.sessionId = sessionId
        self.conversationId = conversationId
        self.sendTime = Date()
        self.direction = MessageConstants.directionFromClient.rawValue
        self.richControl = controlData
    }
}
