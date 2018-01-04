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
    static func chatMessageModel(withMessage message: T) -> ChatMessageModel?
}

extension ChatterboxMessageAdapter {
    static func chatMessageModel(withMessage message: T) -> ChatMessageModel? {
        fatalError("Needs to be implemented by subclasses")
    }
}

// MARK: Boolean Model Adapter

extension BooleanControlViewModel: ChatterboxMessageAdapter {
    typealias T = BooleanControlMessage
    
    static func chatMessageModel(withMessage message: T) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        // FIXME: direction should be an enum. Talk to Marc about it
        let booleanModel = BooleanControlViewModel(id: message.id, label: title, required: required)
        let direction = message.data.direction
        let snowViewModel = ChatMessageModel(model: booleanModel, location: BubbleLocation.location(for: direction))
        return snowViewModel
    }
}

extension SingleSelectControlViewModel: ChatterboxMessageAdapter {
    typealias T = PickerControlMessage
    
    static func chatMessageModel(withMessage message: T) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.data.direction
        var items = [PickerItem]()
        
        message.data.richControl?.uiMetadata?.options.forEach({ option in
            items.append(PickerItem(label: option.label, value: option.value))
        })
        
        let pickerModel = SingleSelectControlViewModel(id: message.id, label: title, required: required, items: items)
        let snowViewModel = ChatMessageModel(model: pickerModel, location: BubbleLocation.location(for: direction))
        return snowViewModel
    }
}

extension TextControlViewModel: ChatterboxMessageAdapter {
    typealias T = OutputTextMessage
    
    static func chatMessageModel(withMessage message: T) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        // FIXME: direction should be an enum. Talk to Marc about it
        let value = message.data.richControl?.value ?? ""
        let direction = message.data.direction
        let textModel = TextControlViewModel(id: message.id, label: title, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation.location(for: direction))
        return snowViewModel
    }
}
