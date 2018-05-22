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
    
    private let chatbotDisplayThrottleDefault = 1.5
    
    internal var chatbotDisplayThrottle: TimeInterval {
        guard let delayMS = chatterbox.session?.settings?.generalSettings?.messageDelay else { return
            chatbotDisplayThrottleDefault
        }
        return TimeInterval(delayMS) / 1000.0
    }

    internal let chatterbox: Chatterbox
    internal var controlData = [ChatMessageModel]()

    internal(set) var conversationId: String?
    internal let typingIndicator = TypingIndicatorViewModel()
    
    internal(set) weak var changeListener: ViewDataChangeListener?

    private var controlMessageBuffer = [ChatMessageModel]()
    private var bufferProcessingTimer: Timer?
    internal var isBufferingEnabled = true
    internal var changeSet = [ModelChangeType]()
    
    internal let logger = Logger.logger(for: "ChatDataController")
    private(set) var theme = Theme()

    static internal let showAllTopicsAction = 999
    static internal let imageUploadControlId = ChatUtil.uuidString()
    
    private(set) var lastMessageDate: Date?
    
    private var reachedBeginningOfHistory = false
    private var undeliveredMessageTimer: Timer?
    
    init(chatterbox: Chatterbox, changeListener: ViewDataChangeListener? = nil) {
        self.chatterbox = chatterbox
        self.chatterbox.chatDataListeners.addListener(self)
        self.changeListener = changeListener
        
        setupUndeliveredSweeper()
    }
    
    deinit {
        Logger.default.logFatal("ChatDataController deinit")
        undeliveredMessageTimer?.invalidate()
    }
    
    func setupUndeliveredSweeper() {
        undeliveredMessageTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let strongSelf = self else { return }

            var index = 0
            strongSelf.controlData.forEach { chatMessage in
                guard !chatMessage.wasMarkedUndelivered else {
                    // was already marked undelivered, no need to do it again
                    return
                }
                
                if chatMessage.isUndelivered {
                    chatMessage.wasMarkedUndelivered = true
                    
                    strongSelf.addModelChange(.update(index: index, oldModel: chatMessage, model: chatMessage))
                    strongSelf.applyModelChanges()
                }
                index += 1
            }
        }
    }
    
    // MARK: - Theme preparation
    
    func loadTheme() {
        if let theme = chatterbox.session?.settings?.brandingSettings?.theme {
            self.theme = theme
        }
        
        applyAppearance()
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
        
        guard data.type == .text || chatterbox.currentConversationHasControlData(forId: data.id) else {
            // no conversations, just skip it
            logger.logError("Control is not from current conversation! ignoring update request")
            return
        }
        
        updateChatterbox(data)
    }
    
    public func sendControlData(_ data: ControlViewModel) {
        guard data.type == .text else {
            logger.logError("Only expecting text controls in sendControlData")
            return
        }
        sendLiveAgentResponse(data)
    }
    
    func loadHistory(_ completion: @escaping (Error?) -> Void) {
        Logger.default.logDebug("Fetching history...")
        
        chatterbox.loadDataFromPersistence { error in
            if let error = error {
                Logger.default.logError("Error loading history: \(error)")
            }
            completion(error)
        }
    }
    
    func fetchOlderMessages(_ completion: @escaping (Int) -> Void) {
        logger.logDebug("Fetching older messages...")
        
        // if we already reach the beginning, no need to try again
        guard reachedBeginningOfHistory == false else {
            completion(0)
            return
        }
        
        chatterbox.fetchOlderMessages { [weak self] count in
            self?.logger.logDebug("Fetch complete with \(count) messages")
            
            self?.reachedBeginningOfHistory = (count == 0)
            
            completion(count)
        }
    }
    
    func refreshUserSession(_ completion: @escaping () -> Void) {
        chatterbox.refreshChatSession {
            self.logger.logInfo("User Session Refreshed")
            
            completion()
        }
    }
    
    internal func addModelChange(_ type: ModelChangeType) {
        changeSet.append(type)
    }
    
    internal func applyModelChanges() {
        if isBufferingEnabled {
            changeListener?.controller(self, didChangeModel: changeSet)
        }
        changeSet.removeAll()
    }
    
    func replaceLastControl(with model: ChatMessageModel) {
        guard controlData.count > 0 else {
            logger.logError("Attempt to replace last control when no control is present!")
            return
        }
        
        setLastMessageDate(to: model)
        // last control is really the first... our list is reversed
        let prevModel = controlData[0]
        controlData[0] = model
        addModelChange(.update(index: 0, oldModel: prevModel, model: model))
        applyModelChanges()
        updateLastMessageDate(from: model)        
    }
    
    fileprivate func addControlToCollection(_ data: ChatMessageModel) {
        // add prepends to the front of the array, as our list is reversed
        controlData = [data] + controlData
    }
    
    fileprivate func appendControlData(_ messageModel: ChatMessageModel) {
        setLastMessageDate(to: messageModel)
        controlData.append(messageModel)
        updateLastMessageDate(from: messageModel)
    }
    
    func addHistoryToCollection(withViewModels viewModels: (message: ControlViewModel, response: ControlViewModel?)) {
        // add response, then message, to the tail-end of the control data
        if let response = viewModels.response {
            addHistoryToCollection(withViewModel: response, location: .right)
        }
        
        addHistoryToCollection(withViewModel: viewModels.message, location: .left)
    }
    
    func addHistoryToCollection(withViewModel viewModel: ControlViewModel, location: BubbleLocation = .left) {
        let message = ChatMessageModel(model: viewModel, messageId: viewModel.id, bubbleLocation: location, theme: theme)
        updatedAvatarURL(model: message, withInstance: chatterbox.serverInstance)
        addHistoryToCollection(withChatModel: message)
    }

    func addHistoryToCollection(withChatModel chatModel: ChatMessageModel) {
        appendControlData(chatModel)
    }
    
    func presentControlData(_ data: ChatMessageModel) {
        if isShowingTypingIndicator() {
            replaceLastControl(with: data)
        } else {
            setLastMessageDate(to: data)
            addControlToCollection(data)
            addModelChange(.insert(index: 0, model: data))
            applyModelChanges()
            updateLastMessageDate(from: data)
        }
    }
    
    func setLastMessageDate(to model: ChatMessageModel) {
        guard let lastMessageDate = self.lastMessageDate else { return }
        model.lastMessageDate = lastMessageDate
    }
    
    func updateLastMessageDate(from model: ChatMessageModel) {
        guard let lastMessageDate = model.controlModel?.messageDate else {
            return
        }
        self.lastMessageDate = lastMessageDate
    }
    
    func presentAuxiliaryDataIfNeeded(forMessage message: ControlData) {
        // Only some controls have auxiliary data. They might appear as part of the conversation table view or on the bottom.
        // If a control does have auxiliary data we only show it if the conversation is in-progress and it is the last control

        guard let conversationId = message.conversationId,
            let conversation = chatterbox.conversation(forId: conversationId),
            conversation.state.isInProgress,
            conversation.lastPendingExchange()?.message.messageId == message.messageId,
            let auxiliaryModel = ChatMessageModel.auxiliaryModel(withMessage: message, theme: theme) else { return }

        bufferControlMessage(auxiliaryModel)
    }
    
    func pushTypingIndicatorIfNeeded() {
        if isShowingTypingIndicator() {
            return
        }
        
        let model = ChatMessageModel(model: typingIndicator, bubbleLocation: .left, theme: theme)
        addControlToCollection(model)
        
        addModelChange(.insert(index: 0, model: model))
        applyModelChanges()
    }
    
    internal func isShowingTypingIndicator() -> Bool {
        guard controlData.count > 0, controlData[0].controlModel?.type == .typingIndicator else {
            return false
        }
        return true
    }
    
    fileprivate func popTypingIndicator() {
        if !isShowingTypingIndicator() {
            return
        }
        controlData.remove(at: 0)
        addModelChange(ModelChangeType.delete(index: 0))
        applyModelChanges()
    }
    
    fileprivate func removeTopicPromptIfPresent() {
        guard let lastControl = controlData.first,
            let button = lastControl.controlModel as? ButtonControlViewModel,
            button.value == ChatDataController.showAllTopicsAction else { return }
        
        // remove the button only - leave the prompts
        controlData.remove(at: 0)
        addModelChange(ModelChangeType.delete(index: 0))
        applyModelChanges()
    }

    fileprivate func removeImageUploadIndicatorIfPresent() {
        guard let lastControl = controlData.first,
            let text = lastControl.controlModel as? TextControlViewModel,
            text.id == ChatDataController.imageUploadControlId else { return }

        controlData.remove(at: 0)
        addModelChange(ModelChangeType.delete(index: 0))
        applyModelChanges()
    }
    
    func sendLiveAgentResponse(_ data: ControlViewModel) {
        if let textViewModel = data as? TextControlViewModel,
           let sessionId = chatterbox.conversationContext.sessionId,
           let conversationId = chatterbox.conversationContext.conversationId,
           let taskId = chatterbox.conversationContext.taskId {
            
            let textMessage = AgentTextControlMessage(withValue: textViewModel.value, sessionId: sessionId, conversationId: conversationId, taskId: taskId)
            chatterbox.update(control: textMessage)
        }
    }
    
    // MARK: - Control Updates
    
    //swiftlint:disable:next cyclomatic_complexity
    func updateChatterbox(_ data: ControlViewModel) {
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
            case .dateTime:
                updateDateTimeData(data, lastPendingMessage)
            case .date, .time:
                updateDateOrTimeData(data, lastPendingMessage)
            case .multiPart:
                updateMultiPartData(data, lastPendingMessage)
            case .fileUpload:
                updateFileUploadData(data, lastPendingMessage)
            default:
                logger.logDebug("Unhandled control type: \(lastPendingMessage.controlType)")
                return
            }
        }
    }
    
    func updateBooleanData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let booleanViewModel = data as? BooleanControlViewModel,
            let boolMessage = lastPendingMessage as? BooleanControlMessage {
            
            var boolResponse = boolMessage
            boolResponse.id = data.id
            boolResponse.data.sendTime = Date()
            boolResponse.data.messageId = ChatUtil.uuidString()
            
            boolResponse.data.richControl?.value = booleanViewModel.resultValue
            
            userDidCompleteMessageExchange(MessageExchange(withMessage: boolMessage, withResponse: boolResponse), markDelivered: false)
            chatterbox.update(control: boolResponse)
        }
    }
    
    func updateInputData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let textViewModel = data as? TextControlViewModel,
            let inputMessage = lastPendingMessage as? InputControlMessage {
            
            var inputResponse = inputMessage
            inputResponse.id = data.id
            inputResponse.data.messageId = ChatUtil.uuidString()
            inputResponse.data.richControl?.value = textViewModel.value
            inputResponse.data.sendTime = Date()
            
            userDidCompleteMessageExchange(MessageExchange(withMessage: inputMessage, withResponse: inputResponse), markDelivered: false)
            chatterbox.update(control: inputResponse)
        }
    }
    
    func updatePickerData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        guard let pickerMessage = lastPendingMessage as? PickerControlMessage else { return }
        
        var pickerResponse = pickerMessage
        pickerResponse.id = data.id
        pickerResponse.data.messageId = ChatUtil.uuidString()
        
        if let carouselViewModel = data as? CarouselControlViewModel {
            pickerResponse.data.richControl?.value = carouselViewModel.resultValue
        } else if let pickerViewModel = data as? SingleSelectControlViewModel {
            pickerResponse.data.richControl?.value = pickerViewModel.resultValue
        }
        pickerResponse.data.sendTime = Date()
        
        userDidCompleteMessageExchange(MessageExchange(withMessage: pickerMessage, withResponse: pickerResponse), markDelivered: false)
        chatterbox.update(control: pickerResponse)
    }
    
    func updateMultiSelectData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let multiSelectViewModel = data as? MultiSelectControlViewModel,
            let multiSelectMessage = lastPendingMessage as? MultiSelectControlMessage {
            
            var multiSelectResponse = multiSelectMessage
            multiSelectResponse.id = multiSelectViewModel.id
            multiSelectResponse.data.messageId = ChatUtil.uuidString()
            multiSelectResponse.data.richControl?.value = multiSelectViewModel.resultValue
            multiSelectResponse.data.sendTime = Date()
            
            userDidCompleteMessageExchange(MessageExchange(withMessage: multiSelectMessage, withResponse: multiSelectResponse), markDelivered: false)
            chatterbox.update(control: multiSelectResponse)
        }
    }
    
    func updateDateTimeData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let dateTimeViewModel = data as? DateTimePickerControlViewModel,
            let dateTimeMessage = lastPendingMessage as? DateTimePickerControlMessage {
            
            var dateTimeResponse = dateTimeMessage
            dateTimeResponse.id = dateTimeViewModel.id
            dateTimeResponse.data.messageId = ChatUtil.uuidString()
            dateTimeResponse.data.sendTime = Date()
            dateTimeResponse.data.richControl?.value = dateTimeViewModel.resultValue
            
            userDidCompleteMessageExchange(MessageExchange(withMessage: dateTimeMessage, withResponse: dateTimeResponse), markDelivered: false)
            chatterbox.update(control: dateTimeResponse)
        }
    }
    
    func updateDateOrTimeData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        // TODO: Add DatePickerControlViewModel
        if let dateTimeViewModel = data as? DateTimePickerControlViewModel,
            let dateTimeMessage = lastPendingMessage as? DateOrTimePickerControlMessage {
            
            var dateTimeResponse = dateTimeMessage
            dateTimeResponse.id = dateTimeViewModel.id
            dateTimeResponse.data.messageId = ChatUtil.uuidString()
            dateTimeResponse.data.sendTime = Date()
            dateTimeResponse.data.richControl?.value = dateTimeViewModel.displayValue
            
            userDidCompleteMessageExchange(MessageExchange(withMessage: dateTimeMessage, withResponse: dateTimeResponse), markDelivered: false)
            chatterbox.update(control: dateTimeResponse)
        }
    }
    
    func updateMultiPartData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        if let buttonViewModel = data as? ButtonControlViewModel,
            let multiPartMessage = lastPendingMessage as? MultiPartControlMessage {
            
            var multiPartResponse = multiPartMessage
            multiPartResponse.id = buttonViewModel.id
            multiPartResponse.data.messageId = ChatUtil.uuidString()
            multiPartResponse.data.sendTime = Date()
            multiPartResponse.data.richControl?.uiMetadata?.index = buttonViewModel.value + 1
            
            userDidCompleteMessageExchange(MessageExchange(withMessage: multiPartMessage, withResponse: multiPartResponse), markDelivered: false)
            chatterbox.update(control: multiPartResponse)
        }
    }
    
    func updateFileUploadData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        guard let fileUploadViewModel = data as? FileUploadViewModel,
            let fileUploadMessage = lastPendingMessage as? FileUploadControlMessage,
            let imageData = fileUploadViewModel.selectedImageData,
            let taskId = fileUploadMessage.data.taskId else {
                return
        }
            
        var fileUploadResponse = fileUploadMessage
        fileUploadResponse.id = data.id
        fileUploadResponse.data.messageId = ChatUtil.uuidString()
        
        let imageName = fileUploadViewModel.imageName ?? ""
        
        replaceWithImageUploadMessage()
        
        chatterbox.apiManager.uploadImage(data: imageData, withName:imageName, taskId: taskId, completion: { [weak self] result in
            fileUploadResponse.data.richControl?.value = result
            fileUploadResponse.data.sendTime = Date()
            
            self?.userDidCompleteMessageExchange(MessageExchange(withMessage: fileUploadMessage, withResponse: fileUploadResponse), markDelivered: false)
            self?.chatterbox.update(control: fileUploadResponse)
        })
    }

    internal func updatedAvatarURL(model: ChatMessageModel, withInstance instance: ServerInstance) {
        if let path = model.avatarURL?.absoluteString {
            let updatedURL = URL(string: path, relativeTo: instance.instanceURL)
            model.avatarURL = updatedURL
        }
    }

    internal func chatMessageModel(withMessage message: ControlData) -> ChatMessageModel? {
        if let messageModel = ChatMessageModel.model(withMessage: message, theme: theme) {
            updatedAvatarURL(model: messageModel, withInstance: chatterbox.serverInstance)
            return messageModel
        }
        return nil
    }

    //swiftlint:disable:next cyclomatic_complexity
    func userDidCompleteMessageExchange(_ messageExchange: MessageExchange, markDelivered: Bool = true) {
        if messageExchange.message.isOutputOnly {
            logger.logError("OutputOnly message is unexpected in didCompleteMessageExchange: caller should use didReceiveControlMessage instead")
        }
        
        switch messageExchange.message.controlType {
        case .boolean:
            guard messageExchange.message is BooleanControlMessage else { fatalError("Could not view message as BooleanControlMessage in ChatDataListener") }
            self.didCompleteBooleanExchange(messageExchange, markDelivered: markDelivered)
        case .input:
            guard messageExchange.message is InputControlMessage else { fatalError("Could not view message as InputControlMessage in ChatDataListener") }
            self.didCompleteInputExchange(messageExchange, markDelivered: markDelivered)
        case .picker:
            guard messageExchange.message is PickerControlMessage else { fatalError("Could not view message as PickerControlMessage in ChatDataListener") }
            self.didCompletePickerExchange(messageExchange, markDelivered: markDelivered)
        case .multiSelect:
            guard messageExchange.message is MultiSelectControlMessage else { fatalError("Could not view message as MultiSelectControlMessage in ChatDataListener") }
            self.didCompleteMultiSelectExchange(messageExchange, markDelivered: markDelivered)
        case .dateTime:
            guard messageExchange.message is DateTimePickerControlMessage else { fatalError("Could not view message as DateTimePickerControlMessage in ChatDataListener") }
            self.didCompleteDateTimeExchange(messageExchange, markDelivered: markDelivered)
        case .date, .time:
            guard messageExchange.message is DateOrTimePickerControlMessage else { fatalError("Could not view message as DateTimePickerControlMessage in ChatDataListener") }
            self.didCompleteDateOrTimeExchange(messageExchange, markDelivered: markDelivered)
        case .multiPart:
            guard messageExchange.message is MultiPartControlMessage else { fatalError("Could not view message as MultiPartControlMessage in ChatDataListener") }
            self.didCompleteMultiPartExchange(messageExchange, markDelivered: markDelivered)
        case .fileUpload:
            guard messageExchange.message is FileUploadControlMessage else { fatalError("Could not view message as FileUploadControlMessage in ChatDataListener") }
            self.didCompleteFileUploadExchange(messageExchange, markDelivered: markDelivered)
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
    private func didCompleteBooleanExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        if let viewModels = controlsForBoolean(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                let messageModel = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
                messageModel.isPending = !markDelivered
                presentControlData(messageModel)
            }
        }
    }
    
    private func didCompleteInputExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        if let viewModels = controlsForInput(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            
            if let response = viewModels.response {
                let messageModel = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
                messageModel.isPending = !markDelivered
                presentControlData(messageModel)
            }
        }
    }
    
    private func didCompletePickerExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        if let viewModels = controlsForPicker(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                let messageModel = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
                messageModel.isPending = !markDelivered
                presentControlData(messageModel)
            }
        }
    }
    
    private func didCompleteMultiSelectExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        // replace the picker with the picker's label, and add the response
        if let viewModels = controlsForMultiSelect(from: messageExchange) {
            replaceOrPresentControlData(viewModels.message, messageId: messageExchange.message.messageId)
            if let response = viewModels.response {
                let messageModel = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
                messageModel.isPending = !markDelivered
                presentControlData(messageModel)
            }
        }
    }
    
    private func didCompleteDateTimeExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
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
                chatMessage.isPending = !markDelivered
                
                if isShowingTypingIndicator() {
                    replaceLastControl(with: chatMessage)
                } else {
                    presentControlData(chatMessage)
                }
                
                shouldReplaceLastControlWithResponse = false
            }
            
            guard let response = viewModels.response else { return }
            
            let answer = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
            answer.isPending = !markDelivered
            
            if shouldReplaceLastControlWithResponse {
                replaceLastControl(with: answer)
            } else {
                presentControlData(answer)
            }
        }
    }
    
    private func didCompleteDateOrTimeExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        if let viewModels = controlsForDateOrTimePicker(from: messageExchange) {
            let lastMessage = controlData.first
            var shouldReplaceLastControlWithResponse = true
            
            // see comment above in didCompleteDateTimeExchange
            
            if lastMessage == nil || lastMessage?.messageId != messageExchange.message.messageId {
                let chatMessage = ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left, theme: theme)
                chatMessage.isPending = !markDelivered
                
                if isShowingTypingIndicator() {
                    replaceLastControl(with: chatMessage)
                } else {
                    presentControlData(chatMessage)
                }
                
                shouldReplaceLastControlWithResponse = false
            }
            
            guard let response = viewModels.response else { return }
            
            let answer = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
            answer.isPending = !markDelivered
            
            if shouldReplaceLastControlWithResponse {
                replaceLastControl(with: answer)
            } else {
                presentControlData(answer)
            }
        }
    }
    
    private func didCompleteMultiPartExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        let typingIndicatorModel = ChatMessageModel(model: typingIndicator, bubbleLocation: .left, theme: theme)
        replaceLastControl(with: typingIndicatorModel)
    }
    
    private func didCompleteFileUploadExchange(_ messageExchange: MessageExchange, markDelivered: Bool) {
        if let viewModels = controlsForFileUpload(from: messageExchange) {
            let messageModel = ChatMessageModel(model: viewModels.message, messageId: messageExchange.message.messageId, bubbleLocation: .left, theme: theme)
            replaceLastControl(with: messageModel)
            if let response = viewModels.response {
                let response = ChatMessageModel(model: response, messageId: messageExchange.response?.messageId, bubbleLocation: .right, theme: theme)
                response.isPending = !markDelivered
                presentControlData(response)
            }
        }
    }
    
    // MARK: - Topic Notifications
    
    func topicWillStart(_ topicInfo: TopicInfo) {
        replaceTopicPromptWithTypingIndicator()
    }
    
    func topicDidStart(_ topicInfo: TopicInfo) {
        conversationId = topicInfo.conversationId
        
        presentTopicTitle(topicInfo: topicInfo)
    }

    func topicDidResume(_ topicInfo: TopicInfo) {
        conversationId = topicInfo.conversationId
        
    }
    
    func topicDidFinish(_ completion: (() -> Void)? = nil) {
        conversationId = nil
        
        flushControlBuffer { [weak self] in
            self?.presentEndOfTopicDividerIfNeeded()
            self?.presentWelcomeMessage()
            self?.presentTopicPrompt()
            
            completion?()
        }
    }

    func agentTopicWillStart() {
        replaceTopicPromptWithTypingIndicator()
        
        // a 'Please Wait' text message will come in between this and the agentDidStart,
        // so we use the typing indicator to show the user that more is coming
    }
    
    func agentTopicDidStart(agentInfo: AgentInfo) {
        let agentName = agentInfo.agentId == "" ? NSLocalizedString("An agent", comment: "placeholder for agent name when none is provided") : agentInfo.agentId
        let message = NSLocalizedString("\(agentName) is now taking your case.", comment: "Default agent responded message to show to user")
        let completionTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message, messageDate: nil)
        bufferControlMessage(ChatMessageModel(model: completionTextControl, bubbleLocation: .left, theme: theme))
    }
    
    func agentTopicDidFinish() {
        flushControlBuffer { [weak self] in
            self?.presentTopicPrompt()
        }
    }
    
    func presentTopicPrompt() {
        // show the intro-message and a button the user can tap to get all topics
        
        if let message = chatterbox.session?.settings?.generalSettings?.introMessage {
            let completionTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message, messageDate: nil)
            bufferControlMessage(ChatMessageModel(model: completionTextControl, bubbleLocation: .left, theme: theme))
            
            let completionActionButton = ButtonControlViewModel(id: ChatUtil.uuidString(), label: "View all Topics", value: ChatDataController.showAllTopicsAction, messageDate: nil)
            let buttonModel = ChatMessageModel(model: completionActionButton, bubbleLocation: .left, theme: theme)
            buttonModel.isAuxiliary = true
            bufferControlMessage(buttonModel)
        }
    }

    func presentWelcomeMessage() {
        let message = chatterbox.session?.settings?.generalSettings?.welcomeMessage ?? NSLocalizedString("Welcome! What can we help you with?", comment: "Default welcome message")
        let welcomeTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message, messageDate: nil)

        bufferControlMessage(ChatMessageModel(model: welcomeTextControl, bubbleLocation: .left, theme: theme))
    }
    
    func replaceWithImageUploadMessage() {
        let message = NSLocalizedString("Uploading image...", comment: "Message displayed when image-upload is uploading to server")
        let uploadingTextControl = TextControlViewModel(id: ChatDataController.imageUploadControlId, value: message, messageDate: nil)
        replaceLastControl(with: ChatMessageModel(model: uploadingTextControl, bubbleLocation: .left, theme: theme))
    }
    
    func presentEndOfTopicDividerIfNeeded() {
        guard let lastControl = controlData.first, lastControl.type != .topicDivider else { return }
        
        presentControlData(ChatMessageModel(type: .topicDivider, theme: theme))
    }
    
    internal func chatModelFromTopicInfo(_ topicInfo: TopicInfo) -> ChatMessageModel {
        var message = topicInfo.topicName ?? ""
        if message.count == 0 {
            message = NSLocalizedString("New Topic", comment: "Default text for new topic indicator, when topic has no name")
        }
        
        let titleTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message, messageDate: nil)
        let messageModel = ChatMessageModel(model: titleTextControl, messageId: titleTextControl.id, bubbleLocation: .right, theme: theme)
        
        return messageModel
    }
    
    func presentTopicTitle(topicInfo: TopicInfo) {
        let messageModel = chatModelFromTopicInfo(topicInfo)
        
        presentControlData(messageModel)
    }
    
    func appendTopicTitle(topicInfo: TopicInfo) {
        let messageModel = chatModelFromTopicInfo(topicInfo)

        addHistoryToCollection(withChatModel: messageModel)
    }
    
    func appendTopicStartDivider(topicInfo: TopicInfo) {
        addHistoryToCollection(withChatModel: ChatMessageModel(type: .topicDivider, theme: theme))
    }
    
    private func replaceTopicPromptWithTypingIndicator() {
        guard let lastControl = controlData.first,
            let button = lastControl.controlModel as? ButtonControlViewModel,
            button.value == ChatDataController.showAllTopicsAction else { return }
        
        let model = ChatMessageModel(model: typingIndicator, bubbleLocation: .left, theme: theme)
        replaceLastControl(with: model)
    }
    
    // MARK: - Control Buffer
    
    func bufferControlMessage(_ control: ChatMessageModel) {
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
                guard let strongSelf = self else { return }
                
                guard strongSelf.controlMessageBuffer.count > 0 else {
                    strongSelf.enableBufferControlProcessing(false)
                    return
                }
                
                self?.presentOneControlFromControlBuffer()
            })
        } else {
            bufferProcessingTimer?.invalidate()
            bufferProcessingTimer = nil
        }
    }

    fileprivate func presentOneControlFromControlBuffer() {
        let control = controlMessageBuffer.remove(at: 0)
        presentControlData(control)

        if controlMessageBuffer.count > 0 {
            pushTypingIndicatorIfNeeded()
        }
    }
    
    fileprivate func flushControlBuffer(immediate: Bool = false, completion: @escaping () -> Void) {
        // disable existing buffer processing
        enableBufferControlProcessing(false)
        
        let interval = immediate ? 0.0 : chatbotDisplayThrottle
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] timer in
            guard let strongSelf = self else { return }
            
            if strongSelf.controlMessageBuffer.count > 0 {
                strongSelf.presentOneControlFromControlBuffer()
            } else {
                timer.invalidate()
                completion()
            }
        })
    }
}
