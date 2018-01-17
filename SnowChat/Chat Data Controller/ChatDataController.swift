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
    }
    
    fileprivate func addControlToCollection(_ data: ChatMessageModel) {
        // add prepends to the front of the array, as our list is reversed
        controlData = [data] + controlData
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
            
            boolMessage.id = booleanViewModel.id
            boolMessage.data.richControl?.value = booleanViewModel.resultValue
            chatterbox.update(control: boolMessage)
        }
    }
    
    fileprivate func updateInputData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let textViewModel = data as? TextControlViewModel,
            var inputMessage = lastPendingMessage as? InputControlMessage {
            
            inputMessage.id = textViewModel.id
            inputMessage.data.richControl?.value = textViewModel.value
            chatterbox.update(control: inputMessage)
        }
    }
    
    fileprivate func updatePickerData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let pickerViewModel = data as? SingleSelectControlViewModel,
            var pickerMessage = lastPendingMessage as? PickerControlMessage {
            
            pickerMessage.id = pickerViewModel.id
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
    
    func chatterbox(_ chatterbox: Chatterbox, willLoadConversation conversationId: String, forChat chatId: String) {
        // disable caching while doing a conversation load
        isBufferingEnabled = false
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didLoadConversation conversationId: String, forChat chatId: String) {
        // re-enable caching and upate the view
        isBufferingEnabled = true
        
        changeListener?.controlllerDidLoadContent(self)
    }
    
    // MARK: - ChatDataListener (from service)
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        var messageClone = message
        messageClone.id = CBData.uuidString()
        if let messageModel = ChatMessageModel.model(withMessage: messageClone) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        var messageClone = message
        messageClone.id = CBData.uuidString()
        if let messageModel = ChatMessageModel.model(withMessage: messageClone) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        var messageClone = message
        messageClone.id = CBData.uuidString()
        if let messageModel = ChatMessageModel.model(withMessage: messageClone) {
            bufferControlMessage(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }

        var messageClone = message
        messageClone.id = CBData.uuidString()
        if let messageModel = ChatMessageModel.model(withMessage: messageClone) {
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
        
        guard messageExchange.isComplete else {
            Logger.default.logError("MessageExchange is not complete in didCompleteMessageExchange method - skipping!")
            return
        }
        
        // a completed boolean exchange results in two text messages, one with the label and once with the value
        
        if let response = messageExchange.response as? BooleanControlMessage,
           let message = messageExchange.message as? BooleanControlMessage {
           
            let label = message.data.richControl?.uiMetadata?.label ?? "???"
            let value = response.data.richControl?.value ?? false
            let valueString = (value ?? false) ? "Yes" : "No"
            
            let questionViewModel = TextControlViewModel(id: message.id, label: "", value: label)
            let answerViewModel = TextControlViewModel(id: response.id, label: "", value: valueString)
            
            popTypingIndicatorIfShown()
            replaceLastControl(with: ChatMessageModel(model: questionViewModel, location: .left))
            presentControlData(ChatMessageModel(model: answerViewModel, location: .right))
        }
   }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompleteInputExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        guard messageExchange.isComplete else {
            Logger.default.logError("MessageExchange is not complete in didCompleteMessageExchange method - skipping!")
            return
        }

        // a completed exchange simply adds a new text output representing the users answer
        if let response = messageExchange.response as? InputControlMessage,
            let value: String = response.data.richControl?.value ?? "" {
            
            let responseViewModel = TextControlViewModel(id: response.id, label: "", value: value)
            
            popTypingIndicatorIfShown()
            presentControlData(ChatMessageModel(model: responseViewModel, location: .right))
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didCompletePickerExchange messageExchange: MessageExchange, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id else {
            return
        }
        
        guard messageExchange.isComplete else {
            Logger.default.logError("MessageExchange is not complete in didCompleteMessageExchange method - skipping!")
            return
        }

        // replace the picker with the picker's label, and add the response
        
        if let response = messageExchange.response as? PickerControlMessage,
            let message = messageExchange.message as? PickerControlMessage,
            let label = message.data.richControl?.uiMetadata?.label,
            let value: String = response.data.richControl?.value ?? "" {
                let selectedOption = response.data.richControl?.uiMetadata?.options.first(where: { option -> Bool in
                    option.value == value
                })
                let questionModel = TextControlViewModel(id: CBData.uuidString(), value: label)
                let answerModel = TextControlViewModel(id: CBData.uuidString(), value: selectedOption?.label ?? value)
            
                popTypingIndicatorIfShown()
                replaceLastControl(with: ChatMessageModel(model: questionModel, location: .left))
                presentControlData(ChatMessageModel(model: answerModel, location: .right))
        }
    }
}
