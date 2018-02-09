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
    var avatarURL: URL?
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
    static func model(withMessage message: ControlData) -> ChatMessageModel? {
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
        case .outputImage:
            guard let controlMessage = message as? OutputImageControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .outputLink:
            guard let controlMessage = message as? OutputLinkControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .outputHtml:
            guard let controlMessage = message as? OutputHtmlControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage)
        case .systemError:
            guard let systemErrorMessage = message as? SystemErrorControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: systemErrorMessage)
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
        
        let booleanModel = BooleanControlViewModel(id: message.messageId, label: title, required: required)
        let direction = message.direction
        let snowViewModel = ChatMessageModel(model: booleanModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: PickerControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.direction
        
        let options = message.data.richControl?.uiMetadata?.options ?? []
        let items = options.map { PickerItem(label: $0.label, value: $0.value) }
        let pickerModel = SingleSelectControlViewModel(id: message.messageId, label: title, required: required, items: items)
        let snowViewModel = ChatMessageModel(model: pickerModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: MultiSelectControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.direction
        
        let options = message.data.richControl?.uiMetadata?.options ?? []
        let items = options.map { PickerItem(label: $0.label, value: $0.value) }
        let multiSelectModel = MultiSelectControlViewModel(id: message.messageId, label: title, required: required, items: items)
        let snowViewModel = ChatMessageModel(model: multiSelectModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputTextControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: InputControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        let direction = message.direction
        
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, location: BubbleLocation(direction: direction), requiresInput: true)
        return snowViewModel
    }
    
    static func model(withMessage message: MultiPartControlMessage) -> ChatMessageModel? {
        guard let nestedControlValue = message.data.richControl?.content?.value,
            let nestedControlType = message.nestedControlType else {
                return nil
        }
        
        let direction = message.direction
        
        var chatMessageModel: ChatMessageModel?
        switch nestedControlType {
        case .text:
            let controlModel = TextControlViewModel(id: ChatUtil.uuidString(), value: nestedControlValue)
            chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
        case .outputHtml:
            let controlModel = OutputHtmlControlViewModel(id: ChatUtil.uuidString(), value: nestedControlValue)
            chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
        case .outputImage:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputImageViewModel(id: ChatUtil.uuidString(), value: url)
                chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
            }
        case .outputLink:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputLinkControlViewModel(id: ChatUtil.uuidString(), value: url)
                chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
            }
        default:
            chatMessageModel = nil
        }
        
        return chatMessageModel
    }
    
    static func buttonModel(withMessage message: MultiPartControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.navigationBtnLabel,
            let index = message.data.richControl?.uiMetadata?.index else {
                return nil
        }
        
        let buttonModel = ButtonControlViewModel(id: message.messageId, label: title, value: index)
        let direction = message.data.direction
        let buttonChatModel = ChatMessageModel(model: buttonModel, location: BubbleLocation(direction: direction))
        return buttonChatModel
    }
    
    static func model(withMessage message: OutputImageControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.direction
        
        guard let url = URL(string: value) else {
            return nil
        }
        
        let outputImageModel = OutputImageViewModel(id: message.messageId, value: url)
        let snowViewModel = ChatMessageModel(model: outputImageModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputLinkControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        
        let outputLinkModel = OutputLinkControlViewModel(id: ChatUtil.uuidString(), value: URL(fileURLWithPath: value))
        let snowViewModel = ChatMessageModel(model: outputLinkModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputHtmlControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        
        let outputHtmlModel = OutputHtmlControlViewModel(id: ChatUtil.uuidString(), value: value)
        let snowViewModel = ChatMessageModel(model: outputHtmlModel, location: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: SystemErrorControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.error.message,
              let instruction = message.data.richControl?.uiMetadata?.error.handler.instruction else {
            return nil
        }
        
        let direction = message.direction
        
        let outputTextModel = TextControlViewModel(id: message.messageId, value: "\(value)\n\(instruction)")
        let textChatModel = ChatMessageModel(model: outputTextModel, location: BubbleLocation(direction: direction), requiresInput: false)
        
        return textChatModel
    }
}
