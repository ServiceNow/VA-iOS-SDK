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
            chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
        case .outputHtml:
            let controlModel = OutputHtmlControlViewModel(id: message.messageId, value: nestedControlValue)
            chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
        case .outputImage:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputImageViewModel(id: message.messageId, value: url)
                chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
            }
        case .outputLink:
            if let url = URL(string: nestedControlValue) {
                let controlModel = OutputLinkControlViewModel(id: message.messageId, value: url)
                chatMessageModel = ChatMessageModel(model: controlModel, location: BubbleLocation(direction: direction))
            }
        case .unknown:
            if let nestedControlTypeString = message.nestedControlTypeString {
                let outputTextModel = TextControlViewModel(id: message.messageId, value: "Unsupported control: \(nestedControlTypeString)")
                chatMessageModel = ChatMessageModel(model: outputTextModel, location: BubbleLocation(direction: direction), requiresInput: false)
            }
        default:
            chatMessageModel = nil
        }
        
        return chatMessageModel
    }
}
