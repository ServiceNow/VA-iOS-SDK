//
//  ChatStateDataStore.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ChatDataStore: ChatEventNotification {
    
    init(storeId: String) {
        id = storeId
    }
    
    func controlEvent(didReceiveBooleanControl data: BooleanControlMessage) {
        addOrUpdate(data)
        publishBooleanControlNotification(data)
    }
    
    func topicEvent(didReceiveStartedTopic event: StartedUserTopicMessage) {
        ignore(action: event)
    }
    
    internal let id: String
    internal var dataSink: [CBStorable] = []
    
    fileprivate func addOrUpdate(_ chatItem: CBStorable) {
        if let index = dataSink.index(where: { $0.uniqueId() == chatItem.uniqueId() }) {
            dataSink[index] = chatItem
        } else {
            dataSink.append(chatItem)
        }
    }
    
    fileprivate func publishBooleanControlNotification(_ data: BooleanControlMessage ) {
        let info: [String: Any] = ["state": data]
        NotificationCenter.default.post(name: ChatNotification.name(forKind: .booleanControl),
                                        object: self,
                                        userInfo: info)
    }
    
//    fileprivate func publishDateControlNotification(_ channel: CBChannel, _ data: CBDateData ) {
//        let info: [String: Any] = ["state": data]
//        NotificationCenter.default.post(name: ChatNotification.name(forKind: .dateControl),
//                                        object: self,
//                                        userInfo: info)
//    }
//    
//    fileprivate func publishInputControlNotification(_ channel: CBChannel, _ data: CBInputData ) {
//        let info: [String: Any] = ["state": data]
//        NotificationCenter.default.post(name: ChatNotification.name(forKind: .inputControl),
//                                        object: self,
//                                        userInfo: info)
//    }
    
    private func ignore(action: CBActionMessageData) {
        Logger.default.logInfo("ChatDataStore ignoring action message: \(action)")
    }
}
