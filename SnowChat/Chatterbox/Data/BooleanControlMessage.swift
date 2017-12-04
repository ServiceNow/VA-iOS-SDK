//
//  BooleanControlMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct BooleanControlMessage: Codable, CBControlData {
    var id: String = UUID().uuidString
    var controlType: CBControlType = .boolean
    
    let type: String
    let data: RichControlData<ControlMessage.ControlWrapper<ControlMessage.UIMetadata>>
 
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
