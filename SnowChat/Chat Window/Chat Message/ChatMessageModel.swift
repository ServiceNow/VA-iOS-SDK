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
    var auxiliaryControlModel: ControlViewModel?
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
        case .multiPart:
            guard let controlMessage = message as? MultiPartControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
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
        let textModel = TextControlViewModel(id: message.id, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation(direction: direction), requiresInput: true)
        return snowViewModel
    }
    
    static func model(withMessage message: MultiPartControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.navigationBtnLabel,
            let index = message.data.richControl?.uiMetadata?.index,
            let nestedControlValue = message.data.richControl?.content?.value,
            let nestedControlType = message.nestedControlType else {
                return nil
        }
        
        let multiPartModel = ButtonControlViewModel(id: message.id, label: title, value: index)
        let direction = message.data.direction
        let snowViewModel = ChatMessageModel(model: multiPartModel, location: BubbleLocation(direction: direction))
        
        var controlModel: ControlViewModel?
        if nestedControlType == .text {
            controlModel = TextControlViewModel(id: CBData.uuidString(), value: nestedControlValue)
        } else {
            print("Something went wrong")
        }
        
        snowViewModel.auxiliaryControlModel = controlModel
        return snowViewModel
    }
}
