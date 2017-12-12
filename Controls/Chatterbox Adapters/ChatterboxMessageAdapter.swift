//
//  ChatterboxMessageAdapter.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// MARK: - Chatterbox Adapter

protocol ChatterboxMessageAdapter where Self: ControlViewModel {
    
    associatedtype T = CBControlData
    associatedtype U = Self
    static func model(withMessage message: T) -> U?
}

extension ChatterboxMessageAdapter {
    static func model(withMessage message: T) -> U? {
        fatalError("Needs to be implemented by subclasses")
    }
}

// MARK: Boolean Model Adapter

extension BooleanControlViewModel: ChatterboxMessageAdapter {
    
    typealias T = BooleanControlMessage
    typealias U = BooleanControlViewModel
    
    static func model(withMessage message: BooleanControlMessage) -> BooleanControlViewModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
            return nil
        }
        
        let booleanModel = BooleanControlViewModel(id: message.id, label: title, required: required)
        return booleanModel
    }
}
