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

enum ChatMessageType {
    case control
    case topicDivider
}

class ChatMessageModel {
    let type: ChatMessageType
    let controlModel: ControlViewModel?
    let requiresInput: Bool
    var messageId: String?
    
    var avatarURL: URL?
    var isAuxiliary: Bool = false
    var bubbleLocation: BubbleLocation?
    
    init(model: ControlViewModel, messageId: String? = nil, bubbleLocation: BubbleLocation, requiresInput: Bool = false) {
        self.type = .control
        self.controlModel = model
        self.bubbleLocation = bubbleLocation
        self.requiresInput = requiresInput
        self.messageId = messageId
    }
    
    init(type: ChatMessageType) {
        guard type == .topicDivider else { fatalError("initializer only supports non-control types") }
        self.type = type
        self.controlModel = nil
        self.requiresInput = false
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
        case .dateTime, .date, .time:
            guard let controlMessage = message as? DateTimePickerControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
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
        case .startTopicMessage:
            guard let startTopicMessage = message as? StartTopicMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: startTopicMessage)
        case .unknown:
            guard let controlMessage = message as? ControlDataUnknown else { fatalError("message is not what it seems in ChatMessageModel") }
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
        
        let booleanModel = BooleanControlViewModel(id: message.messageId, label: title, required: required)
        let direction = message.direction
        let snowViewModel = ChatMessageModel(model: booleanModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
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
        let snowViewModel = ChatMessageModel(model: pickerModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
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
        let snowViewModel = ChatMessageModel(model: multiSelectModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: DateTimePickerControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label else {
                return nil
        }
        
        let direction = message.direction
        
        let textViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: title)
        let snowViewModel = ChatMessageModel(model: textViewModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputTextControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: InputControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        let direction = message.direction
        
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), requiresInput: true)
        return snowViewModel
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
        let snowViewModel = ChatMessageModel(model: outputImageModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputLinkControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        
        let outputLinkModel = OutputLinkControlViewModel(id: message.messageId, value: URL(fileURLWithPath: value))
        let snowViewModel = ChatMessageModel(model: outputLinkModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: OutputHtmlControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.data.direction
        
        let outputHtmlModel = OutputHtmlControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: outputHtmlModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        return snowViewModel
    }
    
    static func model(withMessage message: SystemErrorControlMessage) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.error.message,
              let instruction = message.data.richControl?.uiMetadata?.error.handler.instruction else {
            return nil
        }
        
        let direction = message.direction
        
        let outputTextModel = TextControlViewModel(id: message.messageId, value: "\(value)\n\(instruction)")
        let textChatModel = ChatMessageModel(model: outputTextModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        
        return textChatModel
    }
    
    static func model(withMessage message: ControlDataUnknown) -> ChatMessageModel? {
        let value = message.label ?? ""
        let direction = message.direction
        let outputTextModel = TextControlViewModel(id: ChatUtil.uuidString(), value: "Unsupported control: \(value)")
        let textChatModel = ChatMessageModel(model: outputTextModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction))
        
        return textChatModel
    }
}
