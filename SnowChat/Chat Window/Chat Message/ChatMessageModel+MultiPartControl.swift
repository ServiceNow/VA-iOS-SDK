//
//  ChatMessageModel+MultiPartControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension ChatMessageModel {
    
    // MARK: Nested models for multi part control
    
    static func model(withMessage message: MultiPartControlMessage) -> ChatMessageModel? {
        guard let nestedControlValue = message.data.richControl?.content?.value,
            let nestedControlType = message.nestedControlType else {
                return nil
        }
        
        let direction = message.direction
        
        var chatMessageModel: ChatMessageModel?
        switch nestedControlType {
        case .text:
            let controlModel = TextControlViewModel(id: message.messageId, value: nestedControlValue)
            chatMessageModel = ChatMessageModel(model: controlModel, bubbleLocation: BubbleLocation(direction: direction))
        case .outputHtml:
            let controlModel = OutputHtmlControlViewModel(id: message.messageId, value: nestedControlValue)
            chatMessageModel = ChatMessageModel(model: controlModel, bubbleLocation: BubbleLocation(direction: direction))
        case .outputImage:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputImageViewModel(id: message.messageId, value: url)
                chatMessageModel = ChatMessageModel(model: controlModel, bubbleLocation: BubbleLocation(direction: direction))
            }
        case .outputLink:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputLinkControlViewModel(id: message.messageId, value: url)
                chatMessageModel = ChatMessageModel(model: controlModel, bubbleLocation: BubbleLocation(direction: direction))
            }
        case .unknown:
            if let nestedControlTypeString = message.nestedControlTypeString {
                let outputTextModel = TextControlViewModel(id: message.messageId, value: "Unsupported control: \(nestedControlTypeString)")
                chatMessageModel = ChatMessageModel(model: outputTextModel, bubbleLocation: BubbleLocation(direction: direction), requiresInput: false)
            }
        default:
            chatMessageModel = nil
        }
        
        // Show the "More" button after each nested control
        chatMessageModel?.auxiliaryMessageModel = ChatMessageModel.buttonModel(withMessage: message)
        return chatMessageModel
    }
    
    static func buttonModel(withMessage message: MultiPartControlMessage) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.navigationBtnLabel,
            let index = message.data.richControl?.uiMetadata?.index else {
                return nil
        }
        
        let buttonModel = ButtonControlViewModel(id: message.messageId, label: title, value: index)
        let direction = message.data.direction
        let buttonChatModel = ChatMessageModel(model: buttonModel, bubbleLocation: BubbleLocation(direction: direction))
        return buttonChatModel
    }
}
