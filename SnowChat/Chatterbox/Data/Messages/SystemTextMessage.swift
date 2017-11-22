//
//  SystemTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct SystemTextMessage: Codable {
    
    let type: String
    let data: RichControlData<ControlWrapper>
    
    struct ControlWrapper: Codable {
        let uiType: String = "Boolean"
        let uiMetadata: UIMetadata
        let model: ModelType
    }
    
    struct UIMetadata: Codable {
        let label: String
        let required: Bool
    }
    
    struct ModelType: Codable {
        let type: String
    }
    
    init(withData: RichControlData<ControlWrapper>) {
        type = "systemTextMessage"
        data = withData
    }
}
