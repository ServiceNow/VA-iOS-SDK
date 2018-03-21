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
    
    internal var chatbotDisplayThrottle: Double {
        guard let delayMS = chatterbox.session?.settings?.generalSettings?.messageDelay else { return
            chatbotDisplayThrottleDefault
        }
        return Double(delayMS / 1000)
    }

    internal let chatterbox: Chatterbox
    internal var controlData = [ChatMessageModel]()

    internal(set) var conversationId: String?
    internal let typingIndicator = TypingIndicatorViewModel()
    
    internal weak var changeListener: ViewDataChangeListener?

    private var controlMessageBuffer = [ChatMessageModel]()
    private var bufferProcessingTimer: Timer?
    internal var isBufferingEnabled = true
    internal var changeSet = [ModelChangeType]()
    
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
    
    private func addModelChange(_ type: ModelChangeType) {
        changeSet.append(type)
    }
    
    private func applyModelChanges() {
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
        
        // last control is really the first... our list is reversed
        let prevModel = controlData[0]
        controlData[0] = model
        addModelChange(.update(index: 0, oldModel: prevModel, model: model))
        applyModelChanges()
    }
    
    fileprivate func addControlToCollection(_ data: ChatMessageModel) {
        // add prepends to the front of the array, as our list is reversed
        controlData = [data] + controlData
    }
    
    func addHistoryToCollection(_ viewModels: (message: ControlViewModel, response: ControlViewModel?)) {
        // add response, then message, to the tail-end of the control data
        if let response = viewModels.response {
            controlData.append(ChatMessageModel(model: response, messageId: response.id, bubbleLocation: BubbleLocation.right))
        }
        controlData.append(ChatMessageModel(model: viewModels.message, messageId: viewModels.message.id, bubbleLocation: BubbleLocation.left))
    }
    
    func addHistoryToCollection(_ viewModel: ControlViewModel, location: BubbleLocation = .left) {
        addHistoryToCollection(ChatMessageModel(model: viewModel, messageId: viewModel.id, bubbleLocation: location))
    }

    func addHistoryToCollection(_ chatModel: ChatMessageModel) {
        controlData.append(chatModel)
    }
    
    func presentControlData(_ data: ChatMessageModel) {
        if isShowingTypingIndicator() {
            replaceLastControl(with: data)
        } else {
            addControlToCollection(data)
            addModelChange(.insert(index: 0, model: data))
            applyModelChanges()
        }
    }
    
    func presentAuxiliaryDataIfNeeded(forMessage message: ControlData) {
        guard let auxiliaryModel = ChatMessageModel.auxiliaryModel(withMessage: message) else { return }
        bufferControlMessage(auxiliaryModel)
    }
    
    func pushTypingIndicator() {
        if isShowingTypingIndicator() {
            return
        }
        
        let model = ChatMessageModel(model: typingIndicator, bubbleLocation: BubbleLocation.left)
        addControlToCollection(model)
        
        addModelChange(.insert(index: 0, model: model))
        applyModelChanges()
    }
    
    fileprivate func isShowingTypingIndicator() -> Bool {
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
    
    func sendLiveAgentResponse(_ data: ControlViewModel) {
        if let textViewModel = data as? TextControlViewModel,
           let sessionId = chatterbox.conversationContext.sessionId,
           let conversationId = chatterbox.conversationContext.conversationId,
           let taskId = chatterbox.conversationContext.taskId {
            
            let textMessage = AgentTextControlMessage(withValue: textViewModel.value, sessionId: sessionId, conversationId: conversationId, taskId: taskId)
            chatterbox.update(control: textMessage)
        }
    }
    
    //swiftlint:disable:next cyclomatic_complexity
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
            case .dateTime:
                updateDateTimeData(data, lastPendingMessage)
            case .date, .time:
                updateDateOrTimeData(data, lastPendingMessage)
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
        guard var pickerMessage = lastPendingMessage as? PickerControlMessage else { return }
        pickerMessage.id = ChatUtil.uuidString()
        
        if let carouselViewModel = data as? CarouselControlViewModel {
            pickerMessage.data.richControl?.value = carouselViewModel.resultValue
        } else if let pickerViewModel = data as? SingleSelectControlViewModel {
            pickerMessage.data.richControl?.value = pickerViewModel.resultValue
        }
        
        chatterbox.update(control: pickerMessage)
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
    
    fileprivate func updateDateOrTimeData(_ data: ControlViewModel, _ lastPendingMessage: ControlData) {
        // TODO: Add DatePickerControlViewModel
        if let dateTimeViewModel = data as? DateTimePickerControlViewModel,
            var dateTimeMessage = lastPendingMessage as? DateOrTimePickerControlMessage {
            
            dateTimeMessage.id = dateTimeViewModel.id
            let dateTimeDisplayValue = dateTimeViewModel.displayValue
            dateTimeMessage.data.richControl?.value = dateTimeDisplayValue
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

    internal func chatMessageModel(withMessage message: ControlData) -> ChatMessageModel? {
        
        func modelWithUpdatedAvatarURL(model: ChatMessageModel, withInstance instance: ServerInstance) -> ChatMessageModel {
            if let path = model.avatarURL?.absoluteString {
                let updatedURL = URL(string: path, relativeTo: instance.instanceURL)
                let newModel = model
                newModel.avatarURL = updatedURL
                return newModel
            }
            return model
        }
        
        if var messageModel = ChatMessageModel.model(withMessage: message) {
            messageModel = modelWithUpdatedAvatarURL(model: messageModel, withInstance: chatterbox.serverInstance)
            return messageModel
        }
        return nil
    }

    // MARK: - Topic Notifications
    
    func topicDidStart(_ topicInfo: TopicInfo) {
        conversationId = topicInfo.conversationId
    
        pushTopicStartDivider(topicInfo)
        if topicInfo.topicName != nil {
            pushTopicTitle(topicInfo: topicInfo)
        }
        
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

    func agentTopicWillStart() {
        // TODO: set timer waiting?
    }
    
    func agentTopicDidStart(agentInfo: AgentInfo) {
        let message = NSLocalizedString("An agent is now taking your case.", comment: "Default agent responded message to show to user")
        let completionTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        bufferControlMessage(ChatMessageModel(model: completionTextControl, bubbleLocation: .left))
    }
    
    func agentTopicDidFinish() {
        presentCompletionMessage()
    }
    
    func presentCompletionMessage() {
        let message = NSLocalizedString("Thanks for visiting. If you need anything else, just ask!", comment: "Default end of topic message to show to user")
        let completionTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        bufferControlMessage(ChatMessageModel(model: completionTextControl, bubbleLocation: .left))
    }

    func presentWelcomeMessage() {
        let message = chatterbox.session?.welcomeMessage ?? NSLocalizedString("Welcome! What can we help you with?", comment: "Default welcome message")
        let welcomeTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        
        // NOTE: we do not buffer the welcome message currently - this is intentional
        presentControlData(ChatMessageModel(model: welcomeTextControl, bubbleLocation: .left))
    }
    
    func pushTopicStartDivider(_ topicInfo: TopicInfo) {
        // if there is a typing indicator we want to remove that first
        popTypingIndicator()
        
        // NOTE: we do not buffer the divider currently - this is intentional
        presentControlData(ChatMessageModel(type: .topicDivider))
    }
    
    func pushTopicTitle(topicInfo: TopicInfo) {
        guard let message = topicInfo.topicName else {
            return
        }
        let titleTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        
        // NOTE: we do not buffer the welcome message currently - this is intentional
        presentControlData(ChatMessageModel(model: titleTextControl, bubbleLocation: .right))
    }
    
    func appendTopicTitle(_ topicInfo: TopicInfo) {
        guard let message = topicInfo.topicName else { return }
        let titleTextControl = TextControlViewModel(id: ChatUtil.uuidString(), value: message)
        
        addHistoryToCollection(ChatMessageModel(model: titleTextControl, bubbleLocation: .right))
    }
    
    func appendTopicStartDivider(_ topicInfo: TopicInfo) {
        addHistoryToCollection(ChatMessageModel(type: .topicDivider))
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
