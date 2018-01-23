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
    private var changeListener: ViewDataChangeListener?
    private let typingIndicator = TypingIndicatorViewModel()
    
    private var controlMessageBuffer = [ChatMessageModel]()
    private var bufferProcessingTimer: Timer?
    private var isBufferingEnabled = true
    
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
    
    fileprivate func replaceLastControl(with model: ChatMessageModel) {
        guard controlData.count > 0 else {
            Logger.default.logError("Attempt to replace last control when no control is present!")
            return
        }
        
        // last control is really the first... our list is reversed
        controlData[0] = model
        let changeInfo = ModelChangeInfo(.update, atIndex: 0)
        changeListener?.controller(self, didChangeData: [changeInfo])
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
        popTypingIndicatorIfShown()
        addControlToCollection(data)
        
        let changeInfo = ModelChangeInfo(.insert, atIndex: 0)
        changeListener?.controller(self, didChangeData: [changeInfo])
    }
    
    fileprivate func pushTypingIndicator() {
        addControlToCollection(ChatMessageModel(model: typingIndicator, location: BubbleLocation.left))
        
        let changeInfo = ModelChangeInfo(.insert, atIndex: 0)
        changeListener?.controller(self, didChangeData: [changeInfo])
    }
    
    fileprivate func popTypingIndicatorIfShown() {
        guard controlData.count > 0, controlData[0].controlModel as? TypingIndicatorViewModel != nil else {
            return
        }
        
        controlData.remove(at: 0)
        let changeInfo = ModelChangeInfo(.delete, atIndex: 0)
        changeListener?.controller(self, didChangeData: [changeInfo])
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
    }
}

extension ChatDataController: ChatDataListener {
    
    // MARK: - ChatDataListener (from service)
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        if let messageModel = ChatMessageModel.model(withMessage: message) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        if let messageModel = ChatMessageModel.model(withMessage: message) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        if let messageModel = ChatMessageModel.model(withMessage: message) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTextData message: OutputTextControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }

        if let messageModel = ChatMessageModel.model(withMessage: message) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    private func dataConversionError(controlId: String, controlType: CBControlType) {
        Logger.default.logError("Data Conversion Error: \(controlId) : \(controlType)")
    }
    
    // MARK: - ChatDataListener (from client)
    
    func chatterbox(_ chatterbox: Chatterbox, didCompleteBooleanExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if let viewModels = booleanControlsFromMessageExchange(messageExchange) {
            popTypingIndicatorIfShown()
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, location: .left))
            presentControlData(ChatMessageModel(model: viewModels.response, location: .right))
        }
   }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompleteInputExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if let viewModels = inputControlsFromMessageExchange(messageExchange) {
            popTypingIndicatorIfShown()
            presentControlData(ChatMessageModel(model: viewModels.response, location: .right))
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompletePickerExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        if let viewModels = pickerControlsFromMessageExchange(messageExchange) {
            popTypingIndicatorIfShown()
            replaceLastControl(with: ChatMessageModel(model: viewModels.message, location: .left))
            presentControlData(ChatMessageModel(model: viewModels.response, location: .right))
        }
    }
    
    // MARK: - ChatDataListener (bulk uopdates / history)
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversation conversationId: String, forChat chatId: String) {
        // disable caching while doing a conversation load
        isBufferingEnabled = false
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String) {
        // re-enable caching and upate the view
        isBufferingEnabled = true
        changeListener?.controllerDidLoadContent(self)
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveHistory historyExchange: MessageExchange, forChat chatId: String) {
        guard historyExchange.isComplete else {
            Logger.default.logError("Incomplete message exchange cannot be presented in history view... skipping")
            return
        }
        
        switch historyExchange.message.controlType {
        case .boolean:
            if let viewModels = booleanControlsFromMessageExchange(historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .picker:
            if let viewModels = pickerControlsFromMessageExchange(historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .input:
            if let viewModels = inputControlsFromMessageExchange(historyExchange) {
                addHistoryToCollection((message: viewModels.message, response: viewModels.response))
            }
        case .text:
            if let viewModel = textControlFromMessageExchange(historyExchange) {
                addHistoryToCollection(viewModel)
            }
        default:
            Logger.default.logInfo("Unhandled control type in didReceiveHistory: \(historyExchange.message.controlType)")
        }
        
    }

    // MARK: - Model to ViewModel methods
    
    func booleanControlsFromMessageExchange(_ messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
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
        
        let questionViewModel = TextControlViewModel(id: message.id, label: "", value: label)
        let answerViewModel = TextControlViewModel(id: response.id, label: "", value: valueString)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func inputControlsFromMessageExchange(_ messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
        guard messageExchange.isComplete,
            let response = messageExchange.response as? InputControlMessage,
            let message = messageExchange.message as? InputControlMessage,
            let messageValue: String = message.data.richControl?.uiMetadata?.label,
            let responseValue: String = response.data.richControl?.value ?? "" else {
            
                Logger.default.logError("MessageExchange is not valid in inputControlsFromMessageExchange method - skipping!")
                return nil
        }
        // a completed input exchange is two text controls, with the value of the message and the value of the response
        
        let questionViewModel = TextControlViewModel(id: message.id, value: messageValue)
        let answerViewModel = TextControlViewModel(id: response.id, value: responseValue)
        
        return (message: questionViewModel, response: answerViewModel)
    }
    
    func pickerControlsFromMessageExchange(_ messageExchange: MessageExchange) -> (message: TextControlViewModel, response: TextControlViewModel)? {
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
    
    func textControlFromMessageExchange(_ messageExchange: MessageExchange) -> TextControlViewModel? {
        guard messageExchange.isComplete,
            let textControl = messageExchange.message as? OutputTextControlMessage,
            let value = textControl.data.richControl?.value else {
            
                Logger.default.logError("MessageExchange is not valid in textControlFromMessageExchange method - skipping!")
                return nil
        }
        
        return TextControlViewModel(id: CBData.uuidString(), value: value)
    }
}
