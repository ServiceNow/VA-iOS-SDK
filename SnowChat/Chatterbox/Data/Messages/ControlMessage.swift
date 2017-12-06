//
//  SystemTextMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ControlMessage: Codable {
    
    let type: String
    let data: RichControlData<ControlWrapper<UIMetadata>>
    
    struct ControlWrapper<MetadataType: Codable>: Codable {
        let model: ModelType?
        let uiType: String
        var value: String?
        let uiMetadata: MetadataType?
    }
    
    struct UIMetadata: Codable {
        var label: String?
        var required: Bool?
        
        var error: UIError?
    }
    
    struct ModelType: Codable {
        var type: String?
        var name: String?
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
    
    init(withData: RichControlData<ControlWrapper<UIMetadata>>) {
        type = "systemTextMessage"
        data = withData
    }
}
