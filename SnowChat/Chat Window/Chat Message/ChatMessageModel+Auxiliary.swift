//
//  ChatMessageModel+Auxiliary.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/15/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension ChatMessageModel {
    
    static func auxiliaryModel(withMessage message: ControlData, theme: Theme) -> ChatMessageModel? {
        switch message.controlType {
        case .dateTime, .date, .time:
            return ChatMessageModel.auxiliaryModel(withMessage: message as! DateTimePickerControlMessage, theme: theme)
        case .multiPart:
            return ChatMessageModel.buttonModel(withMessage: message as! MultiPartControlMessage, theme: theme)
        default:
            return nil
        }
    }
    
    static func auxiliaryModel(withMessage message: DateTimePickerControlMessage, theme: Theme) -> ChatMessageModel? {
        guard let title = message.data.richControl?.uiMetadata?.label,
            let required = message.data.richControl?.uiMetadata?.required else {
                return nil
        }
        
        let direction = message.direction
        
        let dateTimeViewModel: DateTimePickerControlViewModel
        switch message.controlType {
        case .dateTime:
            dateTimeViewModel = DateTimePickerControlViewModel(id: message.messageId, label: title, required: required)
        case .date:
            dateTimeViewModel = DatePickerControlViewModel(id: message.messageId, label: title, required: required)
        case .time:
            dateTimeViewModel = TimePickerControlViewModel(id: message.messageId, label: title, required: required)
        default:
            fatalError("Wrong type")
        }
        
        let snowViewModel = ChatMessageModel(model: dateTimeViewModel, messageId: message.messageId, bubbleLocation: BubbleLocation(direction: direction), theme: theme)
        snowViewModel.isAuxiliary = true
        return snowViewModel
    }
}
