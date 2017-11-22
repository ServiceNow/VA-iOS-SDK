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
    var controlType: CBControlType = .controlBoolean
    
    let type: String
    let data: RichControlData<SystemTextMessage.ControlWrapper>
 
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
