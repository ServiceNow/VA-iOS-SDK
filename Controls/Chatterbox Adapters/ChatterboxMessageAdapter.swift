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
    
    static func model(withMessage message: T) -> U? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        // FIXME: direction should be an enum. Talk to Marc about it
        let direction = message.data.direction
        let booleanModel = BooleanControlViewModel(id: message.id, label: title, required: required, direction: ControlDirection.direction(forStringValue: direction))
        return booleanModel
    }
}

extension SingleSelectControlViewModel: ChatterboxMessageAdapter {
    
    typealias T = PickerControlMessage
    typealias U = SingleSelectControlViewModel
    
    static func model(withMessage message: T) -> U? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.data.direction
        var items = [PickerItem]()
        
        message.data.richControl?.uiMetadata?.options.forEach({ option in
            items.append(PickerItem(label: option.label, value: option.value))
        })
        
        let pickerModel = SingleSelectControlViewModel(id: message.id, label: title, required: required, direction: ControlDirection.direction(forStringValue: direction), items: items)
        return pickerModel
    }
}

extension TextControlViewModel: ChatterboxMessageAdapter {
    typealias T = OutputTextMessage
    typealias U = TextControlViewModel
    
    static func model(withMessage message: T) -> U? {
        guard let title = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        // FIXME: direction should be an enum. Talk to Marc about it
        let value = message.data.richControl?.value ?? ""
        let direction = message.data.direction
        let textModel = TextControlViewModel(id: message.id, label: title, value: value, direction: ControlDirection.direction(forStringValue: direction))
        return textModel
    }
}
