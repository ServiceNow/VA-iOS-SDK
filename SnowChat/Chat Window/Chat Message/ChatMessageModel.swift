//
//  SnowControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

enum BubbleLocation {
    case left
    case right
    
    init(direction: MessageDirection) {
        switch direction {
        case .fromClient:
            self = .right
        case .fromServer:
            self = .left
        }
    }
}

class ChatMessageModel {
    
    let controlModel: ControlViewModel
    let location: BubbleLocation
    
    init(model: ControlViewModel, location: BubbleLocation) {
        self.controlModel = model
        self.location = location
    }
}

extension ChatMessageModel {
    
    static func model(withMessage message: BooleanControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let booleanModel = BooleanControlViewModel(id: message.id, label: title, required: required)
        let direction = message.data.direction
        let snowViewModel = ChatMessageModel(model: booleanModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: PickerControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.data.direction
        var items = [PickerItem]()
        
        message.data.richControl?.uiMetadata?.options.forEach({
            items.append(PickerItem(label: $0.label, value: $0.value))
        })
        
        let isMultiselectPicker = message.data.richControl?.uiMetadata?.multiSelect ?? false
        let pickerModel: PickerControlViewModel
        
        if isMultiselectPicker {
            pickerModel = SingleSelectControlViewModel(id: message.id, label: title, required: required, items: items)
        } else {
            pickerModel = MultiSelectControlViewModel(id: message.id, label: title, required: required, items: items)
        }
        
        let snowViewModel = ChatMessageModel(model: pickerModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputTextMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        let textModel = TextControlViewModel(id: message.id, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: InputControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        let direction = message.data.direction
        let textModel = TextControlViewModel(id: message.id, label: "", value: value)
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
}
