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
}
