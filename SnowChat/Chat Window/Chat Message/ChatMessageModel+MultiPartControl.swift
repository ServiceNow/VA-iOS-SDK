//
//  ChatMessageModel+MultiPartControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension ChatMessageModel {
    
    // MARK: Nested models for multi part control
    
    static func model(withMessage message: MultiPartControlMessage, theme: Theme) -> ChatMessageModel? {
        guard let nestedControlValue = message.data.richControl?.content?.value?.rawValue,
            let nestedControlType = message.nestedControlType else {
                return nil
        }

        let direction = message.direction
        
        var chatMessageModel: ChatMessageModel?
        switch nestedControlType {
        case .text:
            let controlModel = TextControlViewModel(id: message.messageId, value: nestedControlValue, messageDate: message.messageTime)
            chatMessageModel = ChatMessageModel(model: controlModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        case .outputHtml:
            let controlModel = OutputHtmlControlViewModel(id: message.messageId, value: nestedControlValue, messageDate: message.messageTime)
            chatMessageModel = ChatMessageModel(model: controlModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        case .outputImage:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputImageViewModel(id: message.messageId, value: url, messageDate: message.messageTime)
                chatMessageModel = ChatMessageModel(model: controlModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
            }
        case .outputLink:
            if let url = URL(string: nestedControlValue),
                let header = message.data.richControl?.content?.uiMetadata?.header {
                let label = message.data.richControl?.content?.uiMetadata?.label                
                let controlModel = OutputLinkControlViewModel(id: message.messageId, label: label, header: header, value: url, messageDate: message.messageTime)
                chatMessageModel = ChatMessageModel(model: controlModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
            }
        case .unknown:
            if let nestedControlTypeString = message.nestedControlTypeString {
                let outputTextModel = TextControlViewModel(id: message.messageId, value: "Unsupported control: \(nestedControlTypeString)", messageDate: message.messageTime)
                chatMessageModel = ChatMessageModel(model: outputTextModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), requiresInput: false, theme: theme)
            }
        default:
            chatMessageModel = nil
        }
        
        return chatMessageModel
    }
    
    static func buttonModel(withMessage message: MultiPartControlMessage, theme: Theme) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.navigationBtnLabel,
            let index = message.data.richControl?.uiMetadata?.index else {
                return nil
        }
        
        let buttonModel = ButtonControlViewModel(id: message.messageId, label: title, value: index, messageDate: message.messageTime)
        let direction = message.direction
        let buttonChatModel = ChatMessageModel(model: buttonModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        buttonChatModel.isAuxiliary = true
        return buttonChatModel
    }
}
