//
//  ChatDataController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
// ChatDataController is the leason between the UI and Chatterbox.
// It is responsible for getting control notifications from Chatterbox, and for sending
// user-entered data back to Chatterbox.
//
// ChatDataController is also responsible for mapping from Chatterbox control messages to specific UI
// controls that should be displayed. For example, if a Boolean message is received from Chatterbox
// the ChatDataController puts a BooleanControl in it's list of controls to display. If a Boolean
// _response_ is received, then it removes the BooleanControl and makes two TextControls: one with the
// original label of the BooleanControl, and one with the user-selected value.
//
// The controls that ChatDataController maintains are ChatMessageModels, stored in an inverted array
// with the last element in the 0th position, and the first element at the end. This is to facilitate
// a rendering style familiar to chat users, where the latest message is at the bottom and the older
// ones scroll off the top of the screen.
//
// In order to prevent many controls coming in at essentially the same time, which makes the UI look
// janky and inelegant, we first put incoming controls into a buffer. Then, we pull them off of the
// buffer at a timed interval, providing a much smoother and more sequential feel to the UI. This buffering
// is disabled during bulk-loads, like when a message stream is loaded from the REST service

import Foundation

class ChatDataController {
    
    private let chatbotDisplayThrottle = 1.5
    
    private(set) var conversationId: String?
    private let chatterbox: Chatterbox
    private var controlData = [ChatMessageModel]()
    private let typingIndicator = TypingIndicatorViewModel()
    
    private weak var changeListener: ViewDataChangeListener?

    private var controlMessageBuffer = [ChatMessageModel]()
    private var bufferProcessingTimer: Timer?
    private var isBufferingEnabled = true
    private var changeSet = [ModelChangeType]()
    internal let logger = Logger.logger(for: "ChatDataController")

    init(chatterbox: Chatterbox, changeListener: ViewDataChangeListener? = nil) {
        self.chatterbox = chatterbox
        self.chatterbox.chatDataListener = self
        self.changeListener = changeListener
    }
    
    func setChangeListener(_ listener: ViewDataChangeListener) {
        changeListener = listener
    }
    
    // MARK: - access to controls
    
    func controlCount() -> Int {
        return controlData.count
    }
    
    func controlForIndex(_ index: Int) -> ChatMessageModel? {
        guard index < controlData.count else {
            return nil
        }
        return controlData[index]
    }

    // updateControlData: called by view layer when a UI control has updated its value
    //
    public func updateControlData(_ data: ControlViewModel, isSkipped: Bool = false) {
        guard controlData.count > 0 else {
            fatalError("No control data exists, nothing to update")
        }
        
        guard data.type == .text || currentConversationHasControlData(forId: data.id) else {
            // no conversations, just skip it
            logger.logError("Control is not from current conversation! ignoring update request")
            return
        }
        
        updateChatterbox(data)
    }
    
    private func currentConversationHasControlData(forId messageId: String) -> Bool {
        return chatterbox.currentConversationHasControlData(forId: messageId)
    }
    
    func loadHistory(_ completion: @escaping (Error?) -> Void) {
        Logger.default.logDebug("Fetching history...")
        
        chatterbox.loadDataFromPersistence { (error) in
            if let error = error {
                Logger.default.logError("Error loading history: \(error)")
            }
            completion(error)
        }
    }
    
    func fetchOlderMessages(_ completion: @escaping (Int) -> Void) {
        logger.logDebug("Fetching older messages...")
        
        chatterbox.fetchOlderMessages { count in
            self.logger.logDebug("Fetch complete with \(count) messages")
            completion(count)
        }
    }
    
    func syncConversation() {
        chatterbox.syncConversation { count in
            self.logger.logInfo("Synchronized \(count) conversations")
        }
    }
    
    private func addChange(_ type: ModelChangeType) {
        changeSet.append(type)
    }
    
    private func applyChanges() {
        if isBufferingEnabled {
            changeListener?.controller(self, didChangeModel: changeSet)
        }
        changeSet.removeAll()
    }
    
    fileprivate func replaceLastControl(with model: ChatMessageModel) {
        guard controlData.count > 0 else {
            logger.logError("Attempt to replace last control when no control is present!")
            return
        }
        
        // last control is really the first... our list is reversed
        let prevModel = controlData[0]
        controlData[0] = model
        addChange(.update(index: 0, oldModel: prevModel, model: model))
        applyChanges()
    }
    
    fileprivate func addControlToCollection(_ data: ChatMessageModel) {
        // add prepends to the front of the array, as our list is reversed
        controlData = [data] + controlData
    }
    
    fileprivate func addHistoryToCollection(_ viewModels: (message: ControlViewModel, response: ControlViewModel?)) {
        // add response, then message, to the tail-end of the control data
        if let response = viewModels.response {
            controlData.append(ChatMessageModel(model: response, messageId: response.id, bubbleLocation: BubbleLocation.right))
        }
        controlData.append(ChatMessageModel(model: viewModels.message, messageId: viewModels.message.id, bubbleLocation: BubbleLocation.left))
    }
    
    fileprivate func addHistoryToCollection(_ viewModel: ControlViewModel, location: BubbleLocation = .left) {
        addHistoryToCollection(ChatMessageModel(model: viewModel, messageId: viewModel.id, bubbleLocation: location))
    }

    fileprivate func addHistoryToCollection(_ chatModel: ChatMessageModel) {
        controlData.append(chatModel)
    }
    
    fileprivate func presentControlData(_ data: ChatMessageModel) {
        if isShowingTypingIndicator() {
            replaceLastControl(with: data)
        } else {
            addControlToCollection(data)
            addChange(.insert(index: 0, model: data))
            applyChanges()
        }
    }
    
    fileprivate func presentAuxiliaryDataIfNeeded(forMessage message: ControlData) {
        guard let auxiliaryModel = ChatMessageModel.auxiliaryModel(withMessage: message) else { return }
        bufferControlMessage(auxiliaryModel)
    }
    
    fileprivate func pushTypingIndicator() {
        if isShowingTypingIndicator() {
            return
        }
        
        let model = ChatMessageModel(model: typingIndicator, bubbleLocation: BubbleLocation.left)
        addControlToCollection(model)
        
        addChange(.insert(index: 0, model: model))
        applyChanges()
    }
    
    fileprivate func isShowingTypingIndicator() -> Bool {
        guard controlData.count > 0, controlData[0].controlModel?.type == .typingIndicator else {
            return false
        }
        return true
    }
    
    fileprivate func updateChatterbox(_ data: ControlViewModel) {
        guard let conversationId = self.conversationId else {
            logger.logError("No ConversationID in updateChatterbox!")
            return
        }
        
        if let lastPendingMessage = chatterbox.lastPendingControlMessage(forConversation: conversationId) {
            switch lastPendingMessage.controlType {
            case .boolean:
                updateBooleanData(data, lastPendingMessage)
            case .input:
                updateInputData(data, lastPendingMessage)
            case .picker:
                updatePickerData(data, lastPendingMessage)
            case .multiSelect:
                updateMultiSelectData(data, lastPendingMessage)
            case .dateTime, .date, .time:
                updateDateTimeData(data, lastPendingMessage)
            case .multiPart:
                updateMultiPartData(data, lastPendingMessage)
            case .inputImage:
                updateInputImageData(data, lastPendingMessage)
            default:
                logger.logDebug("Unhandled control type: \(lastPendingMessage.controlType)")
                return
            }
        }
    }
    
    fileprivate func updateBooleanData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let booleanViewModel = data as? BooleanControlViewModel,
            var boolMessage = lastPendingMessage as? BooleanControlMessage {
            
            boolMessage.id = ChatUtil.uuidString()
            boolMessage.data.richControl?.value = booleanViewModel.resultValue
            chatterbox.update(control: boolMessage)
        }
    }
    
    fileprivate func updateInputData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let textViewModel = data as? TextControlViewModel,
            var inputMessage = lastPendingMessage as? InputControlMessage {
            
            inputMessage.id = ChatUtil.uuidString()
            inputMessage.data.richControl?.value = textViewModel.value
            chatterbox.update(control: inputMessage)
        }
    }
    
    fileprivate func updatePickerData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let pickerViewModel = data as? SingleSelectControlViewModel,
            var pickerMessage = lastPendingMessage as? PickerControlMessage {
            
            pickerMessage.id = ChatUtil.uuidString()
            pickerMessage.data.richControl?.value = pickerViewModel.resultValue
            chatterbox.update(control: pickerMessage)
        }
    }
    
    fileprivate func updateMultiSelectData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let multiSelectViewModel = data as? MultiSelectControlViewModel,
            var multiSelectMessage = lastPendingMessage as? MultiSelectControlMessage {
            
            multiSelectMessage.id = multiSelectViewModel.id
            multiSelectMessage.data.richControl?.value = multiSelectViewModel.resultValue
            chatterbox.update(control: multiSelectMessage)
        }
    }
    
    fileprivate func updateDateTimeData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let dateTimeViewModel = data as? DateTimePickerControlViewModel,
            var dateTimeMessage = lastPendingMessage as? DateTimePickerControlMessage {
            
            dateTimeMessage.id = dateTimeViewModel.id
            dateTimeMessage.data.richControl?.value = dateTimeViewModel.resultValue
            chatterbox.update(control: dateTimeMessage)
        }
    }
    
    fileprivate func updateMultiPartData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let buttonViewModel = data as? ButtonControlViewModel,
            var multiPartMessage = lastPendingMessage as? MultiPartControlMessage {
            
            multiPartMessage.id = buttonViewModel.id
            multiPartMessage.data.richControl?.uiMetadata?.index = buttonViewModel.value + 1
            chatterbox.update(control: multiPartMessage)
        }
    }
    
    fileprivate func updateInputImageData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let inputImageViewModel = data as? InputImageViewModel,
            var inputImageMessage = lastPendingMessage as? InputImageControlMessage {
            
            guard let imageData = inputImageViewModel.selectedImageData,
                let imageName = inputImageViewModel.imageName,
                let taskId = inputImageMessage.data.taskId else { return }
            
            chatterbox.apiManager.uploadImage(data: imageData, withName:imageName, taskId: taskId, completion: { [weak self] result in
                inputImageMessage.data.richControl?.value = result
                self?.chatterbox.update(control: inputImageMessage)
            })
        }
    }

    // MARK: - Topic Notifications
    
    func topicDidStart(_ topicInfo: TopicInfo) {
        conversationId = topicInfo.conversationId
    
        pushTopicStartDivider(topicInfo)
        pushTypingIndicator()
    }

    func topicDidResume(_ topicInfo: TopicInfo) {
        conversationId = topicInfo.conversationId
        
    }
    
    func topicDidFinish(_ topicInfo: TopicInfo) {
        conversationId = nil
        
        // FIXME: add a completion message. This will eventually come from the service but for now we synthesize it
        presentCompletionMessage()
    }

    func presentCompletionMessage() {
        let message = NSLocalizedString("Thanks for visiting. If you need anything else, just ask!", comment: "Default end of topic message to show to user")
        let completionTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        bufferControlMessage(ChatMessageModel(model: completionTextControl, bubbleLocation: .left))
    }

    func presentWelcomeMessage() {
        let message = chatterbox.session?.welcomeMessage ?? "Welcome! What can we help you with?"
        let welcomeTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        // NOTE: we do not buffer the welcome message currently - this is intentional
        presentControlData(ChatMessageModel(model: welcomeTextControl, bubbleLocation: .left))
    }
    
    func pushTopicStartDivider(_ topicInfo: TopicInfo) {
        // NOTE: we do not buffer the divider currently - this is intentional
        presentControlData(ChatMessageModel(type: .topicDivider))
    }
    
    func appendTopicStartDivider(_ topicInfo: TopicInfo) {
        addHistoryToCollection(ChatMessageModel(type: .topicDivider))
    }
    
    // MARK: - Control Buffer
    
    fileprivate func bufferControlMessage(_ control: ChatMessageModel) {
        guard isBufferingEnabled else {
            presentControlData(control)
            return
        }
        
        controlMessageBuffer.append(control)
        
        enableBufferControlProcessing()
    }
    
    fileprivate func enableBufferControlProcessing(_ enabled: Bool = true) {
        if enabled {
            // only create a new timer if there is not one already running
            guard bufferProcessingTimer == nil else { return }
            
            bufferProcessingTimer = Timer.scheduledTimer(withTimeInterval: chatbotDisplayThrottle, repeats: true, block: { [weak self] timer in
                self?.processControlBuffer()
            })
        } else {
            bufferProcessingTimer?.invalidate()
            bufferProcessingTimer = nil
        }
    }

    fileprivate func processControlBuffer() {
        guard controlMessageBuffer.count > 0 else {
            // disable processing the buffer when it is empty - is re-enabled when something is added to buffer (bufferControlMessage)
            enableBufferControlProcessing(false)
            return
        }
        
        let control = controlMessageBuffer.remove(at: 0)
        presentControlData(control)
        
        if controlMessageBuffer.count > 0 {
            pushTypingIndicator()
        }
    }
}

extension ChatDataController: ChatDataListener {

    // MARK: - ChatDataListener (from service)

    func chatterbox(_ chatterbox: Chatterbox, didReceiveControlMessage message: ControlData, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.direction == .fromServer else {
            return
        }
        
        if let messageModel = ChatMessageModel.model(withMessage: message) {
            bufferControlMessage(messageModel)
            
            // Only some controls have auxiliary data. They might appear as part of the conversation table view or on the bottom.
            presentAuxiliaryDataIfNeeded(forMessage: message)
            
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
            guard let chatControl = ChatMessageModel.model(withMessage: message) else { return }
            self.bufferControlMessage(chatControl)
            logger.logDebug("Unknown control type in ChatDataListener didCompleteMessageExchange: \(messageExchange.message.controlType)")
            return  // skip any post-processing, we canot proceed with unknown control
        default:
            logger.logError("Unhandled control type in ChatDataListener didCompleteMessageExchange: \(messageExchange.message.controlType)")
        }
        
        // we updated the controls for the response, so push a typing indicator while we wait for a new control to come in
        pushTypingIndicator()
    }
    
    private func didCompleteBooleanExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForBoolean(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left))
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
            }
        }
   }
    
    private func didCompleteInputExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForInput(from: messageExchange), let response = viewModels.response {
            presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
        }
    }
    
    private func didCompletePickerExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        if let viewModels = controlsForPicker(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left))
            if let response = viewModels.response {
                presentControlData(ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right))
            }
        }
    }
    
    private func didCompleteMultiSelectExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        // replace the picker with the picker's label, and add the response
        if let viewModels = controlsForMultiSelect(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left))
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
        logger.logInfo("Conversation \(conversationId) will load")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) did load")

        if let conversation = chatterbox.conversation(forId: conversationId) {
            if conversation.state == .inProgress {
                // do not push the start-topic divider if this is the active conversation
                return
            }
        }
        let topicId = conversationId
        pushTopicStartDivider(TopicInfo(topicId: topicId, conversationId: conversationId))
    }

    func chatterbox(_ chatterbox: Chatterbox, willLoadConversationHistory conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) will load from history")
        let topicId = conversationId
        
        // NOTE: until the service delivers entire conversations this will cause the occasional extra-divider to appear...
        //       do not fix this as the service is suppossed to fix it
        appendTopicStartDivider(TopicInfo(topicId: topicId, conversationId: conversationId))
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversationHistory conversationId: String, forChat chatId: String) {
        logger.logInfo("Conversation \(conversationId) did load from history")
    }

    func chatterbox(_ chatterbox: Chatterbox, willLoadConversationsForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        logger.logInfo("History will load for \(consumerAccountId) - disabling buffering...")

        // disable caching while doing a hiastory load
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
    
    //swiftlint:disable:next cyclomatic_complexity
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
            if let messageModel = ChatMessageModel.model(withMessage: historyExchange.message),
               let controlModel = messageModel.controlModel {
                addHistoryToCollection(controlModel)
            }
            
        // MARK: - output-only
        case .outputLink:
            if let viewModel = controlForLink(from: historyExchange) {
                addHistoryToCollection(viewModel)
            }

        // MARK: - output-only
        case .outputImage,
             .multiPart,
             .outputHtml,
             .systemError:
            if let messageModel = ChatMessageModel.model(withMessage: historyExchange.message),
               let controlModel = messageModel.controlModel {
                addHistoryToCollection(controlModel)
            }
        
        case .unknown:
            if let viewModel = ChatMessageModel.model(withMessage: historyExchange.message) {
                addHistoryToCollection(viewModel)
            }
            
        // MARK: - unrendered
        case .topicPicker,
             .startTopicMessage,
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
    
    func controlsForPicker(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel?)? {
        guard let message = messageExchange.message as? PickerControlMessage,
            let label = message.data.richControl?.uiMetadata?.label else {
                logger.logError("MessageExchange is not valid in pickerControlsFromMessageExchange method - skipping!")
                return nil
        }
        let questionViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: label)
        
        let answerViewModel: TextControlViewModel?
        
        // a completed picker exchange results in two text messages: the picker's label, and the value of the picker response
        
        if let response = messageExchange.response as? PickerControlMessage,
           let value: String = response.data.richControl?.value ?? "" {
            let selectedOption = response.data.richControl?.uiMetadata?.options.first(where: { option -> Bool in
                option.value == value
            })
            answerViewModel = TextControlViewModel(id: ChatUtil.uuidString(), value: selectedOption?.label ?? value)
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
        
        if let url = URL(string: value) {
            return OutputLinkControlViewModel(id: ChatUtil.uuidString(), value: url)
        }
        
        return nil
    }
}

extension ChatDataController: ContextItemProvider {
    
    func contextMenuItems() -> [ContextMenuItem] {
        let newConversationItem = ContextMenuItem(withTitle: NSLocalizedString("New Conversation", comment: "Context Menu Item Title")) { viewController, sender in
            self.logger.logDebug("New Conversation menu selected")
            
            self.newConversation()
        }
        
        let supportItem = ContextMenuItem(withTitle: NSLocalizedString("Contact Support", comment: "Context Menu Item Title")) { viewController, sender in
            self.logger.logDebug("Contact Support menu selected")
            self.presentSupportOptions(viewController, sender)
        }
        
        let refreshItem = ContextMenuItem(withTitle: NSLocalizedString("Refresh Conversation", comment: "Context Menu Item Title")) { viewController, sender in
            self.logger.logDebug("Refresh Conversation menu selected")
            
            self.syncConversation()
        }
        
        let cancelItem = ContextMenuItem(withTitle: NSLocalizedString("Cancel", comment: "Context Menu Item Title"), style: .cancel) { viewController, sender in
            // nada
        }
        
        return [newConversationItem, supportItem, refreshItem, cancelItem]
    }
    
    fileprivate func newConversation() {
        chatterbox.endConversation()
    }
    
    fileprivate func presentSupportOptions(_ presentingController: UIViewController, _ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: NSLocalizedString("Support Options", comment: "Title for support options popover"), message: nil, preferredStyle: .actionSheet)
        
        let email = UIAlertAction(title: NSLocalizedString("Send Email to Customer Support", comment: "Support Menu item"), style: .default) { (action) in
            // TODO: send email
        }
        
        let agent = UIAlertAction(title: NSLocalizedString("Chat with an Agent", comment: "Support Menu item"), style: .default) { (action) in
            // TODO: transfer to live agent chat
        }
        
        let call = UIAlertAction(title: NSLocalizedString("Call Support (Daily 5AM - 11PM)", comment: "Support Menu item"), style: .default) { (action) in
            // TODO: phone call
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Support Menu item"), style: .cancel) { (action) in
            // nada
        }
        
        alertController.addAction(email)
        alertController.addAction(agent)
        alertController.addAction(call)
        alertController.addAction(cancel)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        presentingController.present(alertController, animated: true, completion: nil)
    }
}
