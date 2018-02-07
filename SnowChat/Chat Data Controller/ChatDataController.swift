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
        
        updateChatterbox(data)
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
        Logger.default.logDebug("Fetching older messages...")
        
        chatterbox.fetchOlderMessages { count in
            Logger.default.logDebug("Fetch complete with \(count) messages")            
            completion(count)
        }
    }
    
    func syncConversation() {
        chatterbox.syncConversation()
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
            Logger.default.logError("Attempt to replace last control when no control is present!")
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
    
    fileprivate func addHistoryToCollection(_ viewModels: (message: ControlViewModel, response: ControlViewModel)) {
        // add response, then message, to the tail-end of the control data
        controlData.append(ChatMessageModel(model: viewModels.response, location: BubbleLocation.right))
        controlData.append(ChatMessageModel(model: viewModels.message, location: BubbleLocation.left))
    }
    
    fileprivate func addHistoryToCollection(_ viewModel: ControlViewModel, location: BubbleLocation = .left) {
        controlData.append(ChatMessageModel(model: viewModel, location: location))
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
    
    fileprivate func pushTypingIndicator() {
        if isShowingTypingIndicator() {
            return
        }
        
        let model = ChatMessageModel(model: typingIndicator, location: BubbleLocation.left)
        addControlToCollection(model)
        
        addChange(.insert(index: 0, model: model))
        applyChanges()
    }
    
    fileprivate func isShowingTypingIndicator() -> Bool {
        guard controlData.count > 0, controlData[0].controlModel.type == .typingIndicator else {
            return false
        }
        
        return true
    }
    
    fileprivate func updateChatterbox(_ data: ControlViewModel) {
        guard let conversationId = self.conversationId else {
            Logger.default.logError("No ConversationID in updateChatterbox!")
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
            case .multiPart:
                updateMultiPartData(data, lastPendingMessage)
            default:
                Logger.default.logDebug("Unhandled control type: \(lastPendingMessage.controlType)")
                return
            }
        }
        
        // AFTER updating the controls, push the typing indicator onto the display stack
        pushTypingIndicator()
    }
    
    fileprivate func updateBooleanData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let booleanViewModel = data as? BooleanControlViewModel,
            var boolMessage = lastPendingMessage as? BooleanControlMessage {
            
            boolMessage.id = CBData.uuidString()
            boolMessage.data.richControl?.value = booleanViewModel.resultValue
            chatterbox.update(control: boolMessage)
        }
    }
    
    fileprivate func updateInputData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let textViewModel = data as? TextControlViewModel,
            var inputMessage = lastPendingMessage as? InputControlMessage {
            
            inputMessage.id = CBData.uuidString()
            inputMessage.data.richControl?.value = textViewModel.value
            chatterbox.update(control: inputMessage)
        }
    }
    
    fileprivate func updatePickerData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let pickerViewModel = data as? SingleSelectControlViewModel,
            var pickerMessage = lastPendingMessage as? PickerControlMessage {
            
            pickerMessage.id = CBData.uuidString()
            pickerMessage.data.richControl?.value = pickerViewModel.resultValue
            chatterbox.update(control: pickerMessage)
        }
    }
    
    fileprivate func updateMultiSelectData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let multiSelectViewModel = data as? MultiSelectControlViewModel,
            var multiSelectMessage = lastPendingMessage as? MultiSelectControlMessage {
            
            multiSelectMessage.id = multiSelectViewModel.id
            multiSelectMessage.data.richControl?.value = multiSelectViewModel.resultValue
            chatterbox.update(control: multiSelectMessage)
        }
    }
    
    fileprivate func updateMultiPartData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let buttonViewModel = data as? ButtonControlViewModel,
            var multiPartMessage = lastPendingMessage as? MultiPartControlMessage {
            
            multiPartMessage.id = buttonViewModel.id
            multiPartMessage.data.richControl?.uiMetadata?.index = buttonViewModel.value + 1
            chatterbox.update(control: multiPartMessage)
        }
    }

    // MARK: - Topic Notifications
    
    func topicDidStart(_ topicMessage: StartedUserTopicMessage) {
        conversationId = topicMessage.data.actionMessage.vendorTopicId
        
        pushTypingIndicator()
    }

    func topicDidFinish(_ topicMessage: TopicFinishedMessage) {
        conversationId = nil
        
        // TEMPORARY: add a completion message. This will eventually come from the service but for now we synthesize it
        presentCompletionMessage()
        
        // TODO: how to treat old messages visually?
    }

    func presentCompletionMessage() {
        let message = NSLocalizedString("Thanks for visiting. If you need anything else, just ask!", comment: "Default end of topic message to show to user")
        let completionTextControl = TextControlViewModel(id: CBData.uuidString(), value: message)
        bufferControlMessage(ChatMessageModel(model: completionTextControl, location: .left))
    }

    func presentWelcomeMessage() {
        let message = chatterbox.session?.welcomeMessage ?? "Welcome! What can we help you with?"
        let welcomeTextControl = TextControlViewModel(id: CBData.uuidString(), value: message)
        // NOTE: we do not buffer the welcome message currently - this is intentional
        presentControlData(ChatMessageModel(model: welcomeTextControl, location: .left))
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

    func chatterbox(_ chatterbox: Chatterbox, didReceiveControlMessage message: CBControlData, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.direction == .fromServer else {
            return
        }
        
        if let messageModel = ChatMessageModel.model(withMessage: message) {
            bufferControlMessage(messageModel)
            
            // show Button control after nested control of multipart is presented
            if message.controlType == .multiPart, let buttonModel = ChatMessageModel.buttonModel(withMessage: message as! MultiPartControlMessage) {
                bufferControlMessage(buttonModel)
            }
            
        } else {
            dataConversionError(controlId: message.uniqueId, controlType: message.controlType)
        }
    }
    
    private func dataConversionError(controlId: String, controlType: CBControlType) {
        Logger.default.logError("Data Conversion Error: \(controlId) : \(controlType)")
    }
    
    // MARK: - ChatDataListener (from client)
    
    //swiftlint:disable:next cyclomatic_complexity
    func chatterbox(_ chatterbox: Chatterbox, didCompleteMessageExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        guard messageExchange.isComplete else {
            Logger.default.logError("MessageExchange is not complete in didCompleteMessageExchange: skipping!")
            return
        }
        
        switch messageExchange.message.controlType {
        case .boolean:
            guard messageExchange.message is BooleanControlMessage,
                messageExchange.response is BooleanControlMessage else { fatalError("Could not view message as BooleanControlMessage in ChatDataListener") }
            self.didCompleteBooleanExchange(messageExchange, forChat: chatId)
        case .input:
            guard messageExchange.message is InputControlMessage,
                messageExchange.response is InputControlMessage else { fatalError("Could not view message as InputControlMessage in ChatDataListener") }
            self.didCompleteInputExchange(messageExchange, forChat: chatId)
        case .picker:
            guard messageExchange.message is PickerControlMessage,
                messageExchange.response is PickerControlMessage else { fatalError("Could not view message as PickerControlMessage in ChatDataListener") }
            self.didCompletePickerExchange(messageExchange, forChat: chatId)
        case .multiSelect:
            guard messageExchange.message is MultiSelectControlMessage,
                messageExchange.response is MultiSelectControlMessage else { fatalError("Could not view message as MultiSelectControlMessage in ChatDataListener") }
            self.didCompleteMultiSelectExchange(messageExchange, forChat: chatId)
        case .multiPart:
            guard messageExchange.message is MultiPartControlMessage,
                messageExchange.response is MultiPartControlMessage else { fatalError("Could not view message as MultiPartControlMessage in ChatDataListener") }
            self.didCompleteMultiPartExchange(messageExchange, forChat: chatId)
        default:
            Logger.default.logError("Unhandled control type in ChatDataListener didCompleteMessageExchange: \(messageExchange.message.controlType)")
        }
    }
    
    private func didCompleteBooleanExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if let viewModels = controlsForBoolean(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, location: .left))
            presentControlData(ChatMessageModel(model: viewModels.response, location: .right))
        }
   }
    
    private func didCompleteInputExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if let viewModels = controlsForInput(from: messageExchange) {
            presentControlData(ChatMessageModel(model: viewModels.response, location: .right))
        }
    }
    
    private func didCompletePickerExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if let viewModels = controlsForPicker(from: messageExchange) {
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, location: .left))
            presentControlData(ChatMessageModel(model: viewModels.response, location: .right))
        }
    }
    
    private func didCompleteMultiSelectExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        // replace the picker with the picker's label, and add the response
        
        if let response = messageExchange.response as? MultiSelectControlMessage,
            let message = messageExchange.message as? MultiSelectControlMessage,
            let label = message.data.richControl?.uiMetadata?.label,
            let values: [String] = response.data.richControl?.value ?? [""] {
            
            let questionModel = TextControlViewModel(id: CBData.uuidString(), value: label)
            
            let options = response.data.richControl?.uiMetadata?.options.filter({ values.contains($0.value) }).map({ $0.label })
            let displayValue = options?.joinedWithCommaSeparator()
            let answerModel = TextControlViewModel(id: CBData.uuidString(), value: displayValue ?? "")
            
            replaceLastControl(with: ChatMessageModel(model: questionModel, location: .left))
            presentControlData(ChatMessageModel(model: answerModel, location: .right))
        }
    }
    
    private func didCompleteMultiPartExchange(_ messageExchange: MessageExchange, forChat chatId: String) {
        let typingIndicatorModel = ChatMessageModel(model: typingIndicator, location: BubbleLocation.left)
        replaceLastControl(with: typingIndicatorModel)        
    }
    
    // MARK: - ChatDataListener (bulk uopdates / history)
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversation conversationId: String, forChat chatId: String) {
        Logger.default.logInfo("Conversation \(conversationId) will load")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String) {
        Logger.default.logInfo("Conversation \(conversationId) did load")
    }

    func chatterbox(_ chatterbox: Chatterbox, willLoadHistoryForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        Logger.default.logInfo("History will load for \(consumerAccountId) - disabling buffering...")

        // disable caching while doing a hiastory load
        isBufferingEnabled = false
        
        changeListener?.controllerWillLoadContent(self)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadHistoryForConsumerAccount consumerAccountId: String, forChat chatId: String) {
        Logger.default.logInfo("History load completed for \(consumerAccountId) - re-enabling buffering.")
        
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
        guard historyExchange.isComplete else {
            Logger.default.logError("Incomplete message exchange cannot be presented in history view... skipping")
            return
        }
        
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
        case .input:
            if let viewModels = controlsForInput(from: historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .text:
            if let viewModel = controlForText(from: historyExchange) {
                addHistoryToCollection(viewModel)
            }
        case .outputImage:
            if let viewModel = controlForImage(from: historyExchange) {
                addHistoryToCollection(viewModel)
            }
        default:
            Logger.default.logInfo("Unhandled control type in didReceiveHistory: \(historyExchange.message.controlType)")
        }
        
    }

    // MARK: - Model to ViewModel methods
    
    func controlsForBoolean(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? BooleanControlMessage,
            let message = messageExchange.message as? BooleanControlMessage else {
            
                Logger.default.logError("MessageExchange is not valid in booleanControlFromMessageExchange method - skipping!")
                return nil
        }
        // a completed boolean exchange results in two text messages, one with the label and once with the value
        
        let label = message.data.richControl?.uiMetadata?.label ?? "???"
        let value = response.data.richControl?.value ?? false
        let valueString = (value ?? false) ? "Yes" : "No"
        
        let questionViewModel = TextControlViewModel(id: CBData.uuidString(), value: label)
        let answerViewModel = TextControlViewModel(id: CBData.uuidString(), value: valueString)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlsForInput(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? InputControlMessage,
            let message = messageExchange.message as? InputControlMessage,
            let messageValue: String = message.data.richControl?.uiMetadata?.label,
            let responseValue: String = response.data.richControl?.value ?? "" else {
            
                Logger.default.logError("MessageExchange is not valid in inputControlsFromMessageExchange method - skipping!")
                return nil
        }
        // a completed input exchange is two text controls, with the value of the message and the value of the response
        
        let questionViewModel = TextControlViewModel(id: CBData.uuidString(), value: messageValue)
        let answerViewModel = TextControlViewModel(id: CBData.uuidString(), value: responseValue)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlsForPicker(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? PickerControlMessage,
            let message = messageExchange.message as? PickerControlMessage,
            let label = message.data.richControl?.uiMetadata?.label,
            let value: String = response.data.richControl?.value ?? "" else {
            
                Logger.default.logError("MessageExchange is not valid in pickerControlsFromMessageExchange method - skipping!")
                return nil
        }
        // a completed picker exchange results in two text messages: the picker's label, and the value of the picker response
        
        let selectedOption = response.data.richControl?.uiMetadata?.options.first(where: { option -> Bool in
            option.value == value
        })
        let questionViewModel = TextControlViewModel(id: CBData.uuidString(), value: label)
        let answerViewModel = TextControlViewModel(id: CBData.uuidString(), value: selectedOption?.label ?? value)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func controlsForMultiSelect(from messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? MultiSelectControlMessage,
            let message = messageExchange.message as? MultiSelectControlMessage,
            let label = message.data.richControl?.uiMetadata?.label,
            let values: [String] = response.data.richControl?.value ?? [""] else {
                Logger.default.logError("MessageExchange is not valid in multiSelectControlsFromMessageExchange method - skipping!")
                return nil
        }

        let questionModel = TextControlViewModel(id: CBData.uuidString(), value: label)
        
        let options = response.data.richControl?.uiMetadata?.options.filter({ values.contains($0.value) }).map({ $0.label })
        let displayValue = options?.joinedWithCommaSeparator()
        let answerModel = TextControlViewModel(id: CBData.uuidString(), value: displayValue ?? "")
        
        return (message: questionModel, response: answerModel)
    }
    
    func controlForText(from messageExchange: MessageExchange) -> TextControlViewModel? {
        guard messageExchange.isComplete,
            let textControl = messageExchange.message as? OutputTextControlMessage,
            let value = textControl.data.richControl?.value else {
            
                Logger.default.logError("MessageExchange is not valid in textControlFromMessageExchange method - skipping!")
                return nil
        }
        
        return TextControlViewModel(id: CBData.uuidString(), value: value)
    }
    
    func controlForImage(from messageExchange: MessageExchange) -> OutputImageViewModel? {
        guard messageExchange.isComplete,
            let textControl = messageExchange.message as? OutputImageControlMessage,
            let value = textControl.data.richControl?.value else {
                Logger.default.logError("MessageExchange is not valid in imageControlFromMessageExchange method - skipping!")
                return nil
        }
        
        if let url = URL(string: value) {
            return OutputImageViewModel(id: CBData.uuidString(), value: url)
        }
        
        return nil
    }
}

extension ChatDataController: ContextItemProvider {
    
    func contextMenuItems() -> [ContextMenuItem] {
        let newConversationItem = ContextMenuItem(withTitle: NSLocalizedString("New Conversation", comment: "Context Menu Item Title")) { viewController, sender in
            Logger.default.logDebug("New Conversation menu selected")
            
            self.newConversation()
        }
        
        let supportItem = ContextMenuItem(withTitle: NSLocalizedString("Contact Support", comment: "Context Menu Item Title")) { viewController, sender in
            Logger.default.logDebug("Contact Support menu selected")
            self.presentSupportOptions(viewController, sender)
        }
        
        let refreshItem = ContextMenuItem(withTitle: NSLocalizedString("Refresh Conversation", comment: "Context Menu Item Title")) { viewController, sender in
            Logger.default.logDebug("Refresh Conversation menu selected")
            
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
        
        let agent = UIAlertAction(title: NSLocalizedString("Chat with and Agent", comment: "Support Menu item"), style: .default) { (action) in
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
