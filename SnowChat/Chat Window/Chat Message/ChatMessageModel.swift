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
    var theme: Theme?
    
    var avatarURL: URL?
    var bubbleLocation: BubbleLocation?
    var isLiveAgentConversation: Bool
    var isAuxiliary = false
    
    init(model: ControlViewModel, messageId: String? = nil, bubbleLocation: BubbleLocation, requiresInput: Bool = false, theme: Theme?, isAgentMessage: Bool = false) {
        self.type = .control
        self.controlModel = model
        self.bubbleLocation = bubbleLocation
        self.requiresInput = requiresInput
        self.messageId = messageId
        self.theme = theme
        self.isLiveAgentConversation = isAgentMessage
    }
    
    init(type: ChatMessageType, theme: Theme?) {
        guard type == .topicDivider else { fatalError("initializer only supports non-control types") }
        self.type = type
        self.controlModel = nil
        self.requiresInput = false
        self.theme = theme
        self.isLiveAgentConversation = false
    }
}

extension ChatMessageModel {
    //swiftlint:disable:next cyclomatic_complexity function_body_length
    static func model(withMessage message: ControlData, theme: Theme?) -> ChatMessageModel? {
        switch message.controlType {
        case .boolean:
            guard let controlMessage = message as? BooleanControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .picker:
            guard let controlMessage = message as? PickerControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .multiSelect:
            guard let controlMessage = message as? MultiSelectControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .input:
            guard let controlMessage = message as? InputControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .text:
            guard let controlMessage = message as? OutputTextControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .multiPart:
            guard let controlMessage = message as? MultiPartControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .dateTime:
            guard let controlMessage = message as? DateTimePickerControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .date, .time:
            guard let controlMessage = message as? DateOrTimePickerControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .outputImage:
            guard let controlMessage = message as? OutputImageControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .outputLink:
            guard let controlMessage = message as? OutputLinkControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .outputHtml:
            guard let controlMessage = message as? OutputHtmlControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .fileUpload:
            guard let controlMessage = message as? FileUploadControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .systemError:
            guard let systemErrorMessage = message as? SystemErrorControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: systemErrorMessage, theme: theme)
        case .startTopic:
            guard let startTopicMessage = message as? StartTopicMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: startTopicMessage, theme: theme)
        case .agentText:
            guard let controlMessage = message as? AgentTextControlMessage else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        case .unknown:
            guard let controlMessage = message as? ControlDataUnknown else { fatalError("message is not what it seems in ChatMessageModel") }
            return model(withMessage: controlMessage, theme: theme)
        default:
            Logger.default.logError("Unhandled control type in ChatMessageModel: \(message.controlType)")
        }
        return nil
    }
    
    static func model(withMessage message: BooleanControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let booleanModel = BooleanControlViewModel(id: message.messageId, label: title, required: required)
        let direction = message.direction
        let snowViewModel = ChatMessageModel(model: booleanModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: FileUploadControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required,
            let itemType = message.data.richControl?.uiMetadata?.itemType else {
                return nil
        }
        
        let fileUploadModel = FileUploadViewModel(id: message.messageId, label: title, required: required, itemType: itemType.rawValue)
        let direction = message.direction
        let snowViewModel = ChatMessageModel(model: fileUploadModel, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: PickerControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.direction
        
        let options = message.data.richControl?.uiMetadata?.options ?? []
        
        let pickerModel: PickerControlViewModel
        if message.data.richControl?.uiMetadata?.style == .carousel {
            
            // TODO: Is there a nicer way to create CarouselItems?
            let items = options.map { (labeledValue: CarouselLabeledValue) -> CarouselItem in
                var url: URL?
                if let attachment = labeledValue.attachment {
                    url = URL(string: attachment)
                }
                
                return CarouselItem(label: labeledValue.label, value: labeledValue.value, attachment: url)
            }
            
            pickerModel = CarouselControlViewModel(id: message.messageId, label: title, required: required, items: items)
        } else {
            let items = options.map { PickerItem(label: $0.label, value: $0.value) }
            pickerModel = SingleSelectControlViewModel(id: message.messageId, label: title, required: required, items: items)
        }
        
        let snowViewModel = ChatMessageModel(model: pickerModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: MultiSelectControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.direction
        
        let options = message.data.richControl?.uiMetadata?.options ?? []
        let items = options.map { PickerItem(label: $0.label, value: $0.value) }
        let multiSelectModel = MultiSelectControlViewModel(id: message.messageId, label: title, required: required, items: items)
        let snowViewModel = ChatMessageModel(model: multiSelectModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: DateTimePickerControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label else {
                return nil
        }
        
        let direction = message.direction
        
        let textViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: title)
        let snowViewModel = ChatMessageModel(model: textViewModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: DateOrTimePickerControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        let direction = message.direction
        
        let textViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: title)
        let snowViewModel = ChatMessageModel(model: textViewModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: OutputTextControlMessage, theme: Theme) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.direction
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: AgentTextControlMessage, theme: Theme?) -> ChatMessageModel? {
        let value = message.data.text
        let direction = message.direction
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme, isAgentMessage: true)

        if let avatarPath = message.data.sender?.avatarPath {
            snowViewModel.avatarURL = URL(string: avatarPath)
        }
        
        return snowViewModel
    }
    
    static func model(withMessage message: InputControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.label else {
            return nil
        }
        
        let direction = message.direction
        
        let textModel = TextControlViewModel(id: message.messageId, value: value)
        let snowViewModel = ChatMessageModel(model: textModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), requiresInput: true, theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: OutputImageControlMessage, theme: Theme) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.direction
        
        guard let url = URL(string: value) else {
            return nil
        }
        
        let outputImageModel = OutputImageViewModel(id: message.messageId, value: url)
        let snowViewModel = ChatMessageModel(model: outputImageModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: OutputLinkControlMessage, theme: Theme) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.direction
        
        guard let url = URL(string: value.action) else { return nil }
        let outputLinkModel = OutputLinkControlViewModel(id: message.messageId, value: url)
        let snowViewModel = ChatMessageModel(model: outputLinkModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: OutputHtmlControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let value = message.data.richControl?.value else {
            return nil
        }
        
        let direction = message.direction
        let outputHtmlModel = OutputHtmlControlViewModel(id: message.messageId, value: value)
        var size = CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric)
        if let width = message.data.richControl?.uiMetadata?.width {
            size.width = CGFloat(width)
        }
        if let height = message.data.richControl?.uiMetadata?.height {
            size.height = CGFloat(height)
        }
        outputHtmlModel.size = size
        
        let snowViewModel = ChatMessageModel(model: outputHtmlModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        return snowViewModel
    }
    
    static func model(withMessage message: SystemErrorControlMessage, theme: Theme?) -> ChatMessageModel? {
        guard let value = message.data.richControl?.uiMetadata?.error.message,
            let instruction = message.data.richControl?.uiMetadata?.error.handler?.instruction else {
            return nil
        }
        
        let direction = message.direction
        
        let outputTextModel = TextControlViewModel(id: message.messageId, value: "\(value)\n\(instruction)")
        let textChatModel = ChatMessageModel(model: outputTextModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        
        return textChatModel
    }
    
    static func model(withMessage message: ControlDataUnknown, theme: Theme?) -> ChatMessageModel? {
        let value = message.label ?? ""
        let direction = message.direction
        let outputTextModel = TextControlViewModel(id: ChatUtil.uuidString(), value: "Unsupported control: \(value)")
        let textChatModel = ChatMessageModel(model: outputTextModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        
        return textChatModel
    }
}
