//
//  ChatterboxMessageAdapter.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/5/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

// Builds UIControls based on a given Chatterbox model

extension ControlProtocol {
    
    static func control(withMessage message: CBControlData) -> ControlProtocol? {
        var uiControl: ControlProtocol?
        switch message.controlType {
        case .boolean:
            if let booleanModel = BooleanControlViewModel.model(withMessage: message as! BooleanControlMessage) {
                uiControl = BooleanPickerControl(model: booleanModel)
            }
            
        default:
            fatalError("control not ready yet")
        }
        
        return uiControl
    }
}

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
        
        let booleanModel = BooleanControlViewModel(id: message.id, title: title, required: required)
        return booleanModel
    }
}
