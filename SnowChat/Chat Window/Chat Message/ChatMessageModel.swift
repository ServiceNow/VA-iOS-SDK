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
    let requiresInput: Bool
    
    init(model: ControlViewModel, location: BubbleLocation, requiresInput: Bool = false) {
        self.controlModel = model
        self.location = location
        self.requiresInput = requiresInput
    }
}

extension ChatMessageModel {
    //swiftlint:disable:next cyclomatic_complexity
    static func model(withMessage message: CBControlData) -> ChatMessageModel? {
        switch message.controlType {
        case .boolean:
            guard let controlMessage = message as? BooleanControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .picker:
            guard let controlMessage = message as? PickerControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .multiSelect:
            guard let controlMessage = message as? MultiSelectControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .input:
            guard let controlMessage = message as? InputControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .text:
            guard let controlMessage = message as? OutputTextControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .outputImage:
            guard let controlMessage = message as? OutputImageControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        default:
            Logger.default.logError("Unhandled control type in ChatMessageModel: \(message.controlType)")
        }
        return nil
    }
    
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
        let options = message.data.richControl?.uiMetadata?.options ?? []
        let items = options.map { PickerItem(label: $0.label, value: $0.value) }
        let pickerModel = SingleSelectControlViewModel(id: message.id, label: title, required: required, items: items)
        let snowViewModel = ChatMessageModel(model: pickerModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: MultiSelectControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.data.direction
        let options = message.data.richControl?.uiMetadata?.options ?? []
        let items = options.map { PickerItem(label: $0.label, value: $0.value) }
        let multiSelectModel = MultiSelectControlViewModel(id: message.id, label: title, required: required, items: items)
        let snowViewModel = ChatMessageModel(model: multiSelectModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputTextControlMessage) -> ChatMessageModel? {
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
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation(direction: direction), requiresInput: true)
        return snowViewModel
    }
    
    static func model(withMessage message: OutputImageControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        
        guard let url = URL(string: value) else {
            return nil
        }
        
        let outputImageModel = OutputImageViewModel(id: CBData.uuidString(), value: url)
        let snowViewModel = ChatMessageModel(model: outputImageModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
}
