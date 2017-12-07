//
//  ChatterboxAdapter.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

protocol ChatterboxAdapter where Self: ControlProtocol {
    
    associatedtype T = CBControlData
    associatedtype U = Self
    static func control(withMessage message: T) -> U?
}

// MARK: Boolean Picker

extension BooleanPickerControl: ChatterboxAdapter {
    
    typealias T = BooleanControlMessage
    typealias U = BooleanPickerControl
    
    static func control(withMessage message: BooleanControlMessage) -> BooleanPickerControl? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
            return nil
        }
        
        let booleanModel = BooleanControlViewModel(id: message.id, title: title, required: required)
        let picker = BooleanPickerControl(model: booleanModel)
        return picker
    }
}
