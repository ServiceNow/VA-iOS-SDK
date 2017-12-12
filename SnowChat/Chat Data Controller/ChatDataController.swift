//
//  ChatDataController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol ViewDataChangeListener {
    func didChange(_ model: ControlViewModel, atIndex index: Int)
}

class ChatDataController {
    
    private let chatterbox: Chatterbox
    private(set) var controlData: [ControlViewModel] = []
    
    public var changeListener: ViewDataChangeListener?
    
    init(chatterbox: Chatterbox) {
        self.chatterbox = chatterbox
        
        chatterbox.chatDataListener = self
    }
    
    public func controlData(atIndex index: Int) -> ControlViewModel? {
        guard index >= 0 && index < controlData.count else {
            Logger.default.logError("Index \(index) out of range")
            return nil
        }
        return controlData[index]
    }
    
    public func update(controlData data: ControlViewModel, atIndex index: Int) -> ControlViewModel? {
        guard index >= 0 && index < controlData.count else {
            Logger.default.logError("Index \(index) out of range")
            return nil
        }
        controlData[index] = data
        changeListener?.didChange(controlData[index], atIndex: index)
        return data
    }
}

extension ChatDataController: ChatDataListener {
    
    func chatterbox(_: Chatterbox, didReceiveBooleanData message: BooleanControlMessage, forChat chatId: String) {
        Logger.default.logDebug("BooleanControl: \(message)")
        
        if let booleanViewModel = BooleanControlViewModel.model(withMessage: message) {
            new(controlData: booleanViewModel)
        } else {
            dataConversionError(controlId: message.uniqueId(), controlType: message.controlType)
        }
    }
    
    func chatterbox(_: Chatterbox, didReceiveInputData message: InputControlMessage, forChat chatId: String) {
        Logger.default.logDebug("InputControl: \(message)")
    }
    
    func chatterbox(_: Chatterbox, didReceivePickerData message: PickerControlMessage, forChat chatId: String) {
        Logger.default.logDebug("PickerControl: \(message)")
    }
    
    func chatterbox(_: Chatterbox, didReceiveTextData message: OutputTextMessage, forChat chatId: String) {
        Logger.default.logDebug("TextControl: \(message)")
    }
    
    private func dataConversionError(controlId: String, controlType: CBControlType) {
        Logger.default.logError("Data Conversion Error: \(controlId) : \(controlType)")
    }
    
    fileprivate func new(controlData data: ControlViewModel) {
        let index = controlData.count
        controlData.append(data)
        changeListener?.didChange(data, atIndex: index)
    }
}
