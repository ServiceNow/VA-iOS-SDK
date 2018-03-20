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
        
        if let messageModel = chatMessageModel(withMessage: message) {
            bufferControlMessage(messageModel)
            
            if isBufferingEnabled {
                // Only some controls have auxiliary data. They might appear as part of the conversation table view or on the bottom.
                // NOTE: we do not show the aux-controls if we are not buffering
                presentAuxiliaryDataIfNeeded(forMessage: message)
            }
            
        } else {
            dataConversionError(controlId: message.uniqueId, controlType: message.controlType)
        }
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
        case .dateTime, .date, .time:
            guard messageExchange.message is DateTimePickerControlMessage else { fatalError("Could not view message as DateTimePickerControlMessage in ChatDataListener") }
            self.didCompleteDateTimeExchange(messageExchange, forChat: chatId)
        case .multiPart:
            guard messageExchange.message is MultiPartControlMessage else { fatalError("Could not view message as MultiPartControlMessage in ChatDataListener") }
            self.didCompleteMultiPartExchange(messageExchange, forChat: chatId)
        case .inputImage:
            guard messageExchange.message is InputImageControlMessage else { fatalError("Could not view message as InputImageControlMessage in ChatDataListener") }
            self.didCompleteInputImageExchange(messageExchange, forChat: chatId)
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
            pushTypingIndicator()
        }
    }
    
    private func replaceOrPresentControlData(_ model: ControlViewModel, messageId: String) {
        let messageModel = ChatMessageModel(model: model, messageId: messageId, bubbleLocation: .left)
        
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
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
            }
        }
    }
    
    private func didCompleteInputExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForInput(from: messageExchange), let response = viewModels.response {
            let message = viewModels.message
            presentControlData(ChatMessageModel(model: message, messageId: messageExchange.message.messageId, bubbleLocation: .left))
            presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
        }
    }
    
    private func didCompletePickerExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForPicker(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
            }
        }
    }
    
    private func didCompleteMultiSelectExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        // replace the picker with the picker's label, and add the response
        if let viewModels = controlsForMultiSelect(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
            }
        }
    }
    
    private func didCompleteDateTimeExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForDateTimePicker(from: messageExchange) {
            
            // We need to check the last displayed control. In case of regular topic flow we will have TextControl and DateTimeControl as a seperate controls but they will represent one message coming from the server.
            let lastMessage = controlData[0]
            
            var shouldReplaceLastControlWithResponse = true
            
            // By comparing ids we can distinguish between loading messages from the history and actual topic flow scenarios.
            // In case when user selected a date during topic flow - we are presenting already question and dateTime picker in the chat (2 controls from one message). Hence we don't want to show question again. And that's what below `if` statement does.
            // THIS is different from other didComplete methods, where we show just one control per message. In those cases we want to replace control with question and insert an answer.
            // `shouldReplaceResponse` flag is set to `true` to indicate that we want to only replace last message (dateTimePicker in this case)
            if lastMessage.messageId != messageExchange.message.messageId {
                replaceLastControl(with: ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left))
                shouldReplaceLastControlWithResponse = false
            }
            
            guard let response = viewModels.response else { return }
            
            let answer = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right)
            if shouldReplaceLastControlWithResponse {
                replaceLastControl(with: answer)
            } else {
                presentControlData(answer)
            }
        }
    }
    
    private func didCompleteMultiPartExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        let typingIndicatorModel = ChatMessageModel(model: typingIndicator, bubbleLocation: BubbleLocation.left)
        replaceLastControl(with: typingIndicatorModel)
    }
    
    private func didCompleteInputImageExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForInputImage(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left))
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
            }
        }
    }
    
    // MARK: - ChatDataListener (bulk uopdates / history)
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversation conversationId: String, forChat chatId: String) {
        guard let conversation = chatterbox.conversation(forId: conversationId) else { fatalError("Conversation cannot be found for id \(conversationId)") }
        
        logger.logInfo("Conversation will load: topicName=\(conversation.topicTypeName) conversationId=\(conversationId) state=\(conversation.state)")
        
        let topicName = conversation.topicTypeName
        let topicId = conversationId
        let topicInfo = TopicInfo(topicId: topicId, topicName: topicName, taskId: nil, conversationId: conversationId)
        pushTopicStartDivider(topicInfo)
        pushTopicTitle(topicInfo: topicInfo)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) did load")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversationHistory conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) will load from history")
        
        if let conversation = chatterbox.conversation(forId: conversationId) {
            let topicId = conversationId
            let topicInfo = TopicInfo(topicId: topicId, topicName: conversation.topicTypeName, taskId: nil, conversationId: conversationId)
            
            // NOTE: until the service delivers entire conversations this will cause the occasional extra-divider to appear...
            //       do not fix this as the service is suppossed to fix it
            appendTopicTitle(topicInfo)
            appendTopicStartDivider(topicInfo)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversationHistory conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) did load from history")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversationsForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        logger.logInfo("History will load for \(consumerAccountId) - disabling buffering...")
        
        // disable caching while doing a history load
        isBufferingEnabled = false
        
        changeListener?.controllerWillLoadContent(self)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversationsForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        logger.logInfo("History load completed for \(consumerAccountId) - re-enabling buffering.")
        
        // see if there are any controls to show - if not, add the welcome message
        // 1 because we are showing typing indicator
        if controlData.count <= 1 {
            presentWelcomeMessage()
        }
        
        isBufferingEnabled = true
        
        changeListener?.controllerDidLoadContent(self)
    }
    
    //swiftlint:disable:next cyclomatic_complexity function_body_length
    func chatterbox(_ chatterbox: Chatterbox, didReceiveHistory historyExchange: MessageExchange, forChat chatId: String) {
        
        switch historyExchange.message.controlType {
        case .boolean:
            if let viewModels = controlsForBoolean(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .picker:
            if let viewModels = controlsForPicker(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .multiSelect:
            if let viewModels = controlsForMultiSelect(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .dateTime, .date, .time:
            if let viewModels = controlsForDateTimePicker(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .input:
            if let viewModels = controlsForInput(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .inputImage:
            if let viewModels = controlsForInputImage(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .text:
            if let messageModel = chatMessageModel(withMessage: historyExchange.message),
                let controlModel = messageModel.controlModel {
                addHistoryToCollection(controlModel)
            }
            
        // MARK: - output-only
        case .outputLink:
            if let viewModel = controlForLink(from: historyExchange) {
                addHistoryToCollection(viewModel)
            }
            
        case .outputImage,
             .multiPart,
             .outputHtml,
             .agentText,
             .systemError:
            if let messageModel = chatMessageModel(withMessage: historyExchange.message),
                let controlModel = messageModel.controlModel {
                addHistoryToCollection(controlModel)
            }
        case .unknown:
            if let viewModel = chatMessageModel(withMessage: historyExchange.message) {
                addHistoryToCollection(viewModel)
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
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label)
        
        let answerViewModel: TextControlViewModel?
        if let response = messageExchange.response as? BooleanControlMessage {
            let value = response.data.richControl?.value ?? false
            let valueString = (value ?? false) ? "Yes" : "No"
            answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: valueString)
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
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label)
        
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
                let url = URL(string: attachmentString) {
                answerViewModel = OutputImageViewModel(id: ChatUtil.uuidString(), label: selectedOption?.label, value: url)
            } else {
                answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: selectedOption?.label ?? value)
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
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label)
        
        let answerModel: TextControlViewModel?
        if let response = messageExchange.response as? MultiSelectControlMessage,
            let values: [String] = response.data.richControl?.value ?? [""] {
            let options = response.data.richControl?.uiMetadata?.options.filter({ values.contains($0.value) }).map({ $0.label })
            let displayValue = options?.joinedWithCommaSeparator()
            answerModel = TextControlViewModel(id: ChatUtil.uuidString(), value: displayValue ?? "")
        } else {
            answerModel = nil
        }
        
        return (message: questionModel, response: answerModel)
    }
    
    func controlsForInputImage(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: OutputImageViewModel?)? {
        guard let message = messageExchange.message as? InputImageControlMessage,
            let label = message.data.richControl?.uiMetadata?.label else {
                logger.logError("MessageExchange is not valid in inputImageControlsFromMessageExchange method - skipping!")
                return nil
        }
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label)
        
        let answerModel: OutputImageViewModel?
        if let response = messageExchange.response as? InputImageControlMessage,
            let value = response.data.richControl?.value ?? "",
            let url = URL(string: value) {
            answerModel = OutputImageViewModel(id: ChatUtil.uuidString(), value: url)
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
        
        let dateFormatter = DateFormatter.formatterForChatterboxControlType(response.controlType)
        let questionModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label)
        let answerModel = TextControlViewModel(id: ChatUtil.uuidString(), value: dateFormatter.string(from: value))
        
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
        
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: messageValue)
        let answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: responseValue)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlForLink(from messageExchange: MessageExchange) -> OutputLinkControlViewModel? {
        guard messageExchange.isComplete,
            let outputLinkControl = messageExchange.message as? OutputLinkControlMessage,
            let value = outputLinkControl.data.richControl?.value else {
                logger.logError("MessageExchange is not valid in outputLinkFromMessageExchange method - skipping!")
                return nil
        }
        
        if let url = URL(string: value.action) {
            return OutputLinkControlViewModel(id: ChatUtil.uuidString(), value: url)
        }
        
        return nil
    }
}
