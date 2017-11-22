//
//  ChatStateDataStore.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ChatDataStore: ChatEventControlNotification {
    
    init(storeId: String) {
        id = storeId
    }
    
    func onBooleanControl(forChannel: CBChannel, withControlData data: BooleanControlMessage) {
        push(data)
        publishBooleanControlNotification(forChannel, data)
    }
    
    func onDateControl(forChannel: CBChannel, withControlData data: CBDateData) {
        push(data)
        publishDateControlNotification(forChannel, data)
    }
    
    func onInputControl(forChannel: CBChannel, withControlData data: CBInputData) {
        push(data)
        publishInputControlNotification(forChannel, data)
    }
    
    fileprivate let id: String
    fileprivate var dataSink: [CBStorable] = []
    
    fileprivate func push(_ chatItem: CBStorable) {
       dataSink.append(chatItem)
    }
    
    fileprivate func publishBooleanControlNotification(_ channel: CBChannel, _ data: BooleanControlMessage ) {
        let info: [String: Any] = ["state": data]
        NotificationCenter.default.post(name: ChatNotification.name(forKind: .booleanControl),
                                        object: self,
                                        userInfo: info)
    }
    
    fileprivate func publishDateControlNotification(_ channel: CBChannel, _ data: CBDateData ) {
        let info: [String: Any] = ["state": data]
        NotificationCenter.default.post(name: ChatNotification.name(forKind: .dateControl),
                                        object: self,
                                        userInfo: info)
    }
    
    fileprivate func publishInputControlNotification(_ channel: CBChannel, _ data: CBInputData ) {
        let info: [String: Any] = ["state": data]
        NotificationCenter.default.post(name: ChatNotification.name(forKind: .inputControl),
                                        object: self,
                                        userInfo: info)
    }
}
