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

import Foundation

protocol ViewDataChangeListener {
    func chatDataController(_ dataController: ChatDataController, didChangeModel model: ChatMessageModel, atIndex index: Int)
}

class ChatDataController {
    
    private(set) var conversationId: String?
    private let chatterbox: Chatterbox
    private var controlData: [ChatMessageModel] = []
    private var changeListener: ViewDataChangeListener?

    init(chatterbox: Chatterbox, changeListener: ViewDataChangeListener? = nil) {
        self.chatterbox = chatterbox
        chatterbox.chatDataListener = self
        
        self.changeListener = changeListener
    }
    
    func setChangeListener(_ listener: ViewDataChangeListener) {
        changeListener = listener
    }
    
    // MARK: - access to controls
    
    func controlCount() -> Int {
        Logger.default.logDebug("DataController Count: \(controlData.count)")
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
            Logger.default.logError("No control data exists, so updating is probably incorrect")
            return
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
    
    fileprivate func addControlData(_ data: ChatMessageModel) {
        // add prepends to the front of the array, as our list is reversed
        controlData = [data] + controlData
    }
    
    fileprivate func addControlDataAndNotify(_ data: ChatMessageModel) {
        addControlData(data)
        changeListener?.chatDataController(self, didChangeModel: data, atIndex: controlData.count - 1)
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
            }
        }
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
    }

    func topicDidFinish(_ topicMessage: TopicFinishedMessage) {
        conversationId = nil
        
        // TODO: how to treat old messages visually?
    }

    func presentWelcomeMessage() {
        let message = chatterbox.session?.welcomeMessage ?? "Welcome! What can we help you with?"
        let welcomeTextControl = TextControlViewModel(id: CBData.uuidString(), value: message)
        addControlDataAndNotify(ChatMessageModel(model: welcomeTextControl, location: .left))
    }
}

extension ChatDataController: ChatDataListener {
    
    // MARK: - ChatDataListener (from service)
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        var messageClone = message
        messageClone.id = CBData.uuidString()
        if let messageModel = ChatMessageModel.makeModel(withMessage: messageClone) {
            addControlDataAndNotify(messageModel)
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
        if let messageModel = ChatMessageModel.makeModel(withMessage: messageClone) {
            addControlDataAndNotify(messageModel)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        var messageClone = message
        messageClone.id = CBData.uuidString()
        if let messageModel = ChatMessageModel.makeModel(withMessage: messageClone) {
            addControlDataAndNotify(messageModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }

        if let value = message.data.richControl?.value {
            let textViewModel = TextControlViewModel(id: CBData.uuidString(), value: value)
            addControlDataAndNotify(ChatMessageModel(model: textViewModel, location: .left))
        }
    }
    
    private func dataConversionError(controlId: String, controlType: CBControlType) {
        Logger.default.logError("Data Conversion Error: \(controlId) : \(controlType)")
    }
    
    // MARK: - ChatDataListener (from client)
    
    func chattebox(_ chatterbox: Chatterbox, didCompleteBooleanExchange messageExchange: MessageExchange, forChat chatId: String) {
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
            
            replaceLastControl(with: ChatMessageModel(model: questionViewModel, location: .left))
            addControlDataAndNotify(ChatMessageModel(model: answerViewModel, location: .right))
        }
   }
    
    func chattebox(_: Chatterbox, didCompleteInputExchange messageExchange: MessageExchange, forChat chatId: String) {
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
                addControlDataAndNotify(ChatMessageModel(model: responseViewModel, location: .right))
        }
    }
    
    func chattebox(_: Chatterbox, didCompletePickerExchange messageExchange: MessageExchange, forChat chatId: String) {
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
            
                replaceLastControl(with: ChatMessageModel(model: questionModel, location: .left))
                addControlDataAndNotify(ChatMessageModel(model: answerModel, location: .right))
        }
    }
}
