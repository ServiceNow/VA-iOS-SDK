//
//  ChatDataController+ChatDataListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension ChatDataController: ChatDataListener {
    
    // MARK: - ChatDataListener (from service)
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveControlMessage message: ControlData, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        guard let messageModel = chatMessageModel(withMessage: message)  else {
            dataConversionError(controlId: message.uniqueId, controlType: message.controlType)
            return
        }
        
        bufferControlMessage(messageModel)
        presentAuxiliaryDataIfNeeded(forMessage: message)
    }
    
    private func dataConversionError(controlId: String, controlType: ChatterboxControlType) {
        logger.logError("Data Conversion Error: \(controlId) : \(controlType)")
    }
    
    // MARK: - ChatDataListener (from client)
    
    //swiftlint:disable:next cyclomatic_complexity
    func chatterbox(_ chatterbox: Chatterbox, didCompleteMessageExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if messageExchange.message.isOutputOnly {
            logger.logError("OutputOnly message is unexpected in didCompleteMessageExchange: caller should use didReceiveControlMessage instead")
        }
        
        switch messageExchange.message.controlType {
        case .boolean:
            guard messageExchange.message is BooleanControlMessage else { fatalError("Could not view message as BooleanControlMessage in ChatDataListener") }
            self.didCompleteBooleanExchange(messageExchange, forChat: chatId)
        case .input:
            guard messageExchange.message is InputControlMessage else { fatalError("Could not view message as InputControlMessage in ChatDataListener") }
            self.didCompleteInputExchange(messageExchange, forChat: chatId)
        case .picker:
            guard messageExchange.message is PickerControlMessage else { fatalError("Could not view message as PickerControlMessage in ChatDataListener") }
            self.didCompletePickerExchange(messageExchange, forChat: chatId)
        case .multiSelect:
            guard messageExchange.message is MultiSelectControlMessage else { fatalError("Could not view message as MultiSelectControlMessage in ChatDataListener") }
            self.didCompleteMultiSelectExchange(messageExchange, forChat: chatId)
        case .dateTime:
            guard messageExchange.message is DateTimePickerControlMessage else { fatalError("Could not view message as DateTimePickerControlMessage in ChatDataListener") }
            self.didCompleteDateTimeExchange(messageExchange, forChat: chatId)
        case .date, .time:
            guard messageExchange.message is DateOrTimePickerControlMessage else { fatalError("Could not view message as DateTimePickerControlMessage in ChatDataListener") }
            self.didCompleteDateOrTimeExchange(messageExchange, forChat: chatId)
        case .multiPart:
            guard messageExchange.message is MultiPartControlMessage else { fatalError("Could not view message as MultiPartControlMessage in ChatDataListener") }
            self.didCompleteMultiPartExchange(messageExchange, forChat: chatId)
        case .fileUpload:
            guard messageExchange.message is FileUploadControlMessage else { fatalError("Could not view message as FileUploadControlMessage in ChatDataListener") }
            self.didCompleteFileUploadExchange(messageExchange, forChat: chatId)
        case .unknown:
            guard let message = messageExchange.message as? ControlDataUnknown else { fatalError("Could not view message as ControlDataUnknown in ChatDataListener") }
            guard let chatControl = chatMessageModel(withMessage: message) else { return }
            self.bufferControlMessage(chatControl)
            logger.logDebug("Unknown control type in ChatDataListener didCompleteMessageExchange: \(messageExchange.message.controlType)")
        return  // skip any post-processing, we canot proceed with unknown control
        default:
            logger.logError("Unhandled control type in ChatDataListener didCompleteMessageExchange: \(messageExchange.message.controlType)")
        }
        
        // we updated the controls for the response, so push a typing indicator while we wait for a new control to come in
        if isBufferingEnabled {
            pushTypingIndicatorIfNeeded()
        }
    }
    
    private func replaceOrPresentControlData(_ model: ControlViewModel, messageId: String) {
        let messageModel = ChatMessageModel(model: model, messageId: messageId, bubbleLocation: .left, theme: theme)
        
        // if buffering, we replace the last control with the new one, otherwise we just present the control
        if isBufferingEnabled {
            replaceLastControl(with: messageModel)
        } else {
            presentControlData(messageModel)
        }
    }
    private func didCompleteBooleanExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForBoolean(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme))
            }
        }
    }
    
    private func didCompleteInputExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForInput(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme))
            }
        }
    }
    
    private func didCompletePickerExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForPicker(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme))
            }
        }
    }
    
    private func didCompleteMultiSelectExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        // replace the picker with the picker's label, and add the response
        if let viewModels = controlsForMultiSelect(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme))
            }
        }
    }
    
    private func didCompleteDateTimeExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForDateTimePicker(from: messageExchange) {
            
            // We need to check the last displayed control. In case of regular topic flow we will have TextControl and DateTimeControl as a seperate controls but they will represent one message coming from the server.
            let lastMessage = controlData.first
            var shouldReplaceLastControlWithResponse = true
            
            // By comparing ids we can distinguish between loading messages from the history and actual topic flow scenarios.
            // In case when user selected a date during topic flow - we are already presenting the question and the dateTime picker (2 controls from one message).
            // Hence we don't want to show question again.
            // During the history load the last control will not be for this message so we _do_ show the question
            //
            // THIS is different from other didComplete methods, where we show just one control per message. In those cases we want to replace control with question and insert an answer.

            if lastMessage == nil || lastMessage?.messageId != messageExchange.message.messageId {
                let chatMessage = ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left, theme: theme)
                
                if isShowingTypingIndicator() {
                    replaceLastControl(with: chatMessage)
                } else {
                    presentControlData(chatMessage)
                }
                
                shouldReplaceLastControlWithResponse = false
            }
            
            guard let response = viewModels.response else { return }
            
            let answer = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
            if shouldReplaceLastControlWithResponse {
                replaceLastControl(with: answer)
            } else {
                presentControlData(answer)
            }
        }
    }
    
    private func didCompleteDateOrTimeExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForDateOrTimePicker(from: messageExchange) {
            let lastMessage = controlData.first
            var shouldReplaceLastControlWithResponse = true

            // see comment above in didCompleteDateTimeExchange
            
            if lastMessage == nil || lastMessage?.messageId != messageExchange.message.messageId {
                let chatMessage = ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left, theme: theme)
                
                if isShowingTypingIndicator() {
                    replaceLastControl(with: chatMessage)
                } else {
                    presentControlData(chatMessage)
                }
                
                shouldReplaceLastControlWithResponse = false
            }
            
            guard let response = viewModels.response else { return }
            
            let answer = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
            if shouldReplaceLastControlWithResponse {
                replaceLastControl(with: answer)
            } else {
                presentControlData(answer)
            }
        }
    }
    
    private func didCompleteMultiPartExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        let typingIndicatorModel = ChatMessageModel(model: typingIndicator, bubbleLocation: .left, theme: theme)
        replaceLastControl(with: typingIndicatorModel)
    }
    
    private func didCompleteFileUploadExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForFileUpload(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left, theme: theme))
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme))
            }
        }
    }
    
    // MARK: - ChatDataListener (bulk uopdates / history)
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversation conversationId: String, forChat chatId: String) {
        guard let conversation = chatterbox.conversation(forId: conversationId) else { fatalError("Conversation cannot be found for id \(conversationId)") }
        logger.logInfo("Conversation will load: topicName=\(conversation.topicTypeName) conversationId=\(conversationId) state=\(conversation.state)")
        
        if !conversation.isPartial {
            let topicName = conversation.topicTypeName
            let topicId = conversationId
            let topicInfo = TopicInfo(topicId: topicId, topicName: topicName, taskId: nil, conversationId: conversationId)
            presentTopicTitle(topicInfo: topicInfo)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String) {
        guard let conversation = chatterbox.conversation(forId: conversationId) else { fatalError("Conversation cannot be found for id \(conversationId)") }
        logger.logInfo("Conversation did load: topicName=\(conversation.topicTypeName) conversationId=\(conversationId) state=\(conversation.state)")

        if let conversation = chatterbox.conversation(forId: conversationId), !conversation.state.isInProgress {
            presentEndOfTopicDividerIfNeeded()
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversationHistory conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) will load from history")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversationHistory conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) did load from history")

        if let conversation = chatterbox.conversation(forId: conversationId) {
            
            if !conversation.isPartial {
                let topicId = conversationId
                let topicInfo = TopicInfo(topicId: topicId, topicName: conversation.topicTypeName, taskId: nil, conversationId: conversationId)
                appendTopicTitle(topicInfo: topicInfo)
                appendTopicStartDivider(topicInfo: topicInfo)
            }
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversationsForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        logger.logInfo("History will load for \(consumerAccountId) - disabling buffering...")
        
        // disable caching while doing a history load
        isBufferingEnabled = false
        
        changeListener?.controllerWillLoadContent(self)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversationsForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        logger.logInfo("History load completed for \(consumerAccountId) - re-enabling buffering.")
        
        isBufferingEnabled = true
        
        if controlData.count == 0 {
            presentWelcomeMessage()
            presentTopicPrompt()
        }
        
        changeListener?.controllerDidLoadContent(self)
    }
    
    //swiftlint:disable:next cyclomatic_complexity function_body_length
    func chatterbox(_ chatterbox: Chatterbox, didReceiveHistory historyExchange: MessageExchange, forChat chatId: String) {
        
        switch historyExchange.message.controlType {
        case .boolean:
            if let viewModels = controlsForBoolean(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .picker:
            if let viewModels = controlsForPicker(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .multiSelect:
            if let viewModels = controlsForMultiSelect(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .dateTime:
            if let viewModels = controlsForDateTimePicker(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .date, .time:
            if let viewModels = controlsForDateOrTimePicker(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .input:
            if let viewModels = controlsForInput(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .fileUpload:
            if let viewModels = controlsForFileUpload(from: historyExchange) {
                addHistoryToCollection(withViewModels: (message: viewModels.message, response: viewModels.response))
            }
        case .text:
            if let messageModel = chatMessageModel(withMessage: historyExchange.message) {
                addHistoryToCollection(withChatModel: messageModel)
            }
            
        // MARK: - output-only
        case .outputLink:
            if let viewModel = controlForLink(from: historyExchange) {
                addHistoryToCollection(withViewModel: viewModel)
            }
            
        case .outputImage,
             .multiPart,
             .outputHtml,
             .agentText,
             .systemError:
            if let messageModel = chatMessageModel(withMessage: historyExchange.message) {
                addHistoryToCollection(withChatModel: messageModel)
            }
        case .unknown:
            if let messageModel = chatMessageModel(withMessage: historyExchange.message) {
                addHistoryToCollection(withChatModel: messageModel)
            }
            
        // MARK: - unrendered
        case .topicPicker,
             .startTopic,
             .cancelTopic,
             .contextualAction:
            break
        }
    }
    
    // MARK: - Model to ViewModel methods
    
    func controlsForBoolean(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel?)? {
        guard let message = messageExchange.message as? BooleanControlMessage else {
            logger.logError("MessageExchange is not valid in booleanControlFromMessageExchange method - skipping!")
            return nil
        }
        // a completed boolean exchange results in two text messages, one with the label and once with the value
        // an incomplete boolean results is just the question as a text message
        
        let label = message.data.richControl?.uiMetadata?.label ?? "???"
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label, messageDate: message.messageTime)
        
        let answerViewModel: TextControlViewModel?
        if let response = messageExchange.response as? BooleanControlMessage {
            let value = response.data.richControl?.value ?? false
            let valueString = (value ?? false) ? "Yes" : "No"
            answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: valueString, messageDate: response.messageTime)
        } else {
            answerViewModel = nil
        }
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlsForPicker(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: ControlViewModel?)? {
        guard let message = messageExchange.message as? PickerControlMessage,
            let label = message.data.richControl?.uiMetadata?.label else {
                logger.logError("MessageExchange is not valid in pickerControlsFromMessageExchange method - skipping!")
                return nil
        }
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label, messageDate: message.messageTime)
        
        let answerViewModel: ControlViewModel?
        
        // a completed picker exchange results in two text messages: the picker's label, and the value of the picker response
        
        if let response = messageExchange.response as? PickerControlMessage,
            let value: String = response.data.richControl?.value ?? "" {
            let selectedOption = response.data.richControl?.uiMetadata?.options.first(where: { option -> Bool in
                option.value == value
            })
            
            // If the message is of carousel style we want to show output image, not text
            if response.data.richControl?.uiMetadata?.style == .carousel,
                let attachmentString = selectedOption?.attachment,
                var url = URL(string: attachmentString) {
                
                // if the url is relative, make it relative to the instanceURL
                if url.host == nil {
                    url = URL(string: attachmentString, relativeTo: chatterbox.serverInstance.instanceURL) ?? url
                }
                
                answerViewModel = OutputImageViewModel(id: ChatUtil.uuidString(), label: selectedOption?.label, value: url, messageDate: response.messageTime)
            } else {
                answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: selectedOption?.label ?? value, messageDate: response.messageTime)
            }
        } else {
            answerViewModel = nil
        }
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlsForMultiSelect(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel?)? {
        guard let message = messageExchange.message as? MultiSelectControlMessage,
            let label = message.data.richControl?.uiMetadata?.label else {
                logger.logError("MessageExchange is not valid in multiSelectControlsFromMessageExchange method - skipping!")
                return nil
        }
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label, messageDate: message.messageTime)
        
        let answerModel: TextControlViewModel?
        if let response = messageExchange.response as? MultiSelectControlMessage,
            let values: [String] = response.data.richControl?.value ?? [""] {
            let options = response.data.richControl?.uiMetadata?.options.filter({ values.contains($0.value) }).map({ $0.label })
            let displayValue = options?.joinedWithCommaSeparator()
            answerModel = TextControlViewModel(id: ChatUtil.uuidString(), value: displayValue ?? "", messageDate: response.messageTime)
        } else {
            answerModel = nil
        }
        
        return (message: questionModel, response: answerModel)
    }
    
    func controlsForFileUpload(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: OutputImageViewModel?)? {
        guard let message = messageExchange.message as? FileUploadControlMessage,
            let label = message.data.richControl?.uiMetadata?.label else {
                logger.logError("MessageExchange is not valid in fileUploadControlsFromMessageExchange method - skipping!")
                return nil
        }
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label, messageDate: message.messageTime)
        
        let answerModel: OutputImageViewModel?
        if let response = messageExchange.response as? FileUploadControlMessage,
            let value = response.data.richControl?.value ?? "",
            let url = URL(string: value) {
            answerModel = OutputImageViewModel(id: ChatUtil.uuidString(), value: url, messageDate: response.messageTime)
        } else {
            answerModel = nil
        }
        
        return (message: questionModel, response: answerModel)
    }
    
    func controlsForDateTimePicker(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel?)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? DateTimePickerControlMessage,
            let message = messageExchange.message as? DateTimePickerControlMessage,
            let label = message.data.richControl?.uiMetadata?.label,
            let value: Date = response.data.richControl?.value ?? Date() else {
                logger.logError("MessageExchange is not valid in dateTimePickerControlsFromMessageExchange method - skipping!")
                return nil
        }
        
        let dateFormatter = DateFormatter.localDisplayFormatter(for: response.controlType)
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label, messageDate: message.messageTime)
        let answerModel = TextControlViewModel(id: ChatUtil.uuidString(), value: dateFormatter.string(from: value), messageDate: response.messageTime)
        
        return (message: questionModel, response: answerModel)
    }
    
    func controlsForDateOrTimePicker(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel?)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? DateOrTimePickerControlMessage,
            let message = messageExchange.message as? DateOrTimePickerControlMessage,
            let label = message.data.richControl?.uiMetadata?.label,
            let value = response.data.richControl?.value ?? "" else {
                logger.logError("MessageExchange is not valid in dateOrTimePickerControlsFromMessageExchange method - skipping!")
                return nil
        }
        
        // Takes string date or time and returns localized string (i.e. turns "2018-03-21" into Mar 21, 2018)
        let displayValue = DateFormatter.glideDisplayString(for: value, for: response.controlType)
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label, messageDate: message.messageTime)
        let answerModel = TextControlViewModel(id: ChatUtil.uuidString(), value: displayValue, messageDate: response.messageTime)
        
        return (message: questionModel, response: answerModel)
    }
    
    func controlsForInput(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel?)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? InputControlMessage,
            let message = messageExchange.message as? InputControlMessage,
            let messageValue: String = message.data.richControl?.uiMetadata?.label,
            let responseValue: String = response.data.richControl?.value ?? "" else {
                logger.logError("MessageExchange is not valid in inputControlsFromMessageExchange method - skipping!")
                return nil
        }
        
        // a completed input exchange is two text controls, with the value of the message and the value of the response
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: messageValue, messageDate: message.messageTime)
        let answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: responseValue, messageDate: response.messageTime)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlForLink(from messageExchange: MessageExchange) -> OutputLinkControlViewModel? {
        guard messageExchange.isComplete,
            let outputLinkControl = messageExchange.message as? OutputLinkControlMessage,
            let value = outputLinkControl.data.richControl?.value,
            let header = outputLinkControl.data.richControl?.uiMetadata?.header else {
                logger.logError("MessageExchange is not valid in outputLinkFromMessageExchange method - skipping!")
                return nil
        }
        
        let label = outputLinkControl.data.richControl?.uiMetadata?.label
        
        if let url = URL(string: value.action) {
            return OutputLinkControlViewModel(id: ChatUtil.uuidString(), label: label, header: header, value: url, messageDate: outputLinkControl.messageTime)
        }
        
        return nil
    }
}
