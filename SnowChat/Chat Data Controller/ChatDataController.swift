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
// response is received, then it removes the BooleanControl and makes two TextControls, one with the
// original label of the BooleanControl, and one with the user-selected value.
//
// The control that ChatDataController maintains are in an inverted array, with the last element in
// the 0th position, and the first element at the end. this is to facilitate a rendering style where
// familiar to chat UI's, where the latest message is at the bottom and the older ones scroll off the
// top of the screen.

import Foundation

protocol ViewDataChangeListener {
    func chatDataController(_ dataController: ChatDataController, didChangeModel model: ControlViewModel, atIndex index: Int)
}

class ChatDataController {
    
    var conversationId: String?
    public var changeListener: ViewDataChangeListener?
    private let chatterbox: Chatterbox
    private var controlData: [ControlViewModel] = []
    
    init(chatterbox: Chatterbox) {
        self.chatterbox = chatterbox
        
        chatterbox.chatDataListener = self
    }
    
    public func updateControlData(_ data: ControlViewModel, isSkipped: Bool = false) {
        guard controlData.count > 0 else {
            Logger.default.logError("No control data exists, so updating is probably incorrect")
            return
        }
        
        // TODO: how to handle skip?
        updateChatterbox(data)
    }
    
    func controlCount() -> Int {
        Logger.default.logDebug("DataController Count: \(controlData.count)")
        return controlData.count
    }
    
    func controlForIndex(_ index: Int) -> ControlViewModel? {
        guard index < controlData.count else {
            return nil
        }
        return controlData[index]
    }
    
    func topicDidStart(_ topicMessage: StartedUserTopicMessage) {
        conversationId = topicMessage.data.actionMessage.vendorTopicId
    }

    func topicDidFinish(_ topicMessage: TopicFinishedMessage) {
        conversationId = nil
        
        // TODO: how to treat old messages visually?
    }

    func presentWelcomeMessage() {
        let message = chatterbox.session?.welcomeMessage ?? "Welcome! What can we help you with?"
        let welcomeTextControl = TextControlViewModel(label: "", value: message, direction: ControlDirection.inbound)
        addControlDataAndNotify(welcomeTextControl)
    }
    
    fileprivate func replaceLastControl(with model: ControlViewModel) {
        guard controlData.count > 0 else {
            Logger.default.logError("Attempt to replace last control when no control is present!")
            return
        }
        
        // last control is really the first... our list is reversed
        controlData[0] = model
    }
    
    fileprivate func addControlData(_ data: ControlViewModel) {
        // add prepends to the front of the array, as our list is reversed
        controlData = [data] + controlData
    }
    
    fileprivate func addControlDataAndNotify(_ data: ControlViewModel) {
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
            
            boolMessage.data.richControl?.value = booleanViewModel.resultValue ?? false
            chatterbox.update(control: boolMessage)
        }
    }
    
    fileprivate func updateInputData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let textViewModel = data as? TextControlViewModel,
           var inputMessage = lastPendingMessage as? InputControlMessage {
            
            inputMessage.data.richControl?.value = textViewModel.value
            chatterbox.update(control: inputMessage)
        }
    }
    
    fileprivate func updatePickerData(_ data: ControlViewModel, _ lastPendingMessage: CBControlData) {
        if let pickerViewModel = data as? SingleSelectControlViewModel,
           var pickerMessage = lastPendingMessage as? PickerControlMessage {
            
            pickerMessage.data.richControl?.value = pickerViewModel.resultValue
            chatterbox.update(control: pickerMessage)
        }
    }
}

extension ChatDataController: ChatDataListener {
    
    // MARK: Chatterbox control notifications: these are controls sent to the client from the virtual agent
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        if let booleanViewModel = BooleanControlViewModel.model(withMessage: message) {
            addControlDataAndNotify(booleanViewModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        if let value = message.data.richControl?.uiMetadata?.label {
            let textViewModel = TextControlViewModel(label: "", value: value, direction: ControlDirection.inbound)
            addControlDataAndNotify(textViewModel)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }
        
        if let pickerViewModel = SingleSelectControlViewModel.model(withMessage: message) {
            addControlDataAndNotify(pickerViewModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String) {
        guard chatterbox.id == self.chatterbox.id, message.data.direction == .fromServer else {
            return
        }

        if let value = message.data.richControl?.value {
            let textViewModel = TextControlViewModel(label: "", value: value, direction: ControlDirection.inbound)
            addControlDataAndNotify(textViewModel)
        }
    }
    
    // MARK: Chatterbox response notifications: these are user-entered responses to controls sent previously
    
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
            
            let questionViewModel = TextControlViewModel(id: message.id, label: "", value: label, direction: ControlDirection.inbound)
            let answerViewModel = TextControlViewModel(id: message.id, label: "", value: valueString, direction: ControlDirection.outbound)
            
            replaceLastControl(with: questionViewModel)
            addControlDataAndNotify(answerViewModel)
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
                let responseViewModel = TextControlViewModel(id: response.id, label: "", value: value, direction: ControlDirection.outbound)
                addControlDataAndNotify(responseViewModel)
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
                let questionModel = TextControlViewModel(label: "", value: label, direction: ControlDirection.inbound)
                let answerModel = TextControlViewModel(label: "", value: selectedOption?.label ?? value, direction: ControlDirection.outbound)
            
                replaceLastControl(with: questionModel)
                addControlDataAndNotify(answerModel)
        }
    }
    
    private func dataConversionError(controlId: String, controlType: CBControlType) {
        Logger.default.logError("Data Conversion Error: \(controlId) : \(controlType)")
    }
}
