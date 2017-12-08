//
//  SystemTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ControlMessage<ValueType: Codable, MetadataType: Codable>: Codable {
    let type: String
    let data: RichControlData<ControlWrapper<ValueType, MetadataType>>
}

struct ControlWrapper<ValueType: Codable, MetadataType: Codable>: Codable {
    let model: ControlModel?
    let uiType: String
    let uiMetadata: MetadataType?
    var value: ValueType?
}

struct ControlModel: Codable {
    var type: String?
    var name: String?
}

struct UIMetadata: Codable {
    var label: String?
    var required: Bool?
    
    var error: UIError?
}

struct UIError: Codable {
    var handler: UIHandler?
    var message: String
    var code: String
}

struct UIHandler: Codable {
    var type: String
    var instruction: String
}
