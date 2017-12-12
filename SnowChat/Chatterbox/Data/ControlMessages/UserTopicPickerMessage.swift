//
//  UserTopicPickerMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct UserTopicPickerMessage: Codable, CBControlData {
    
    func uniqueId() -> String {
        return id
    }
    
    var id: String = UUID().uuidString
    
    var controlType: CBControlType = .topicPicker
    
    var type: String
    var data: RichControlData<ControlWrapper>
    
    struct ControlWrapper: Codable {
        let uiType: String
        var model: ControlModel
        var value: String?
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}
