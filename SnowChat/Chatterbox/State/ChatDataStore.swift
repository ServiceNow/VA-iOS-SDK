//
//  ChatStateDataStore.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ChatDataStore: ChatMessageNotification {
    
    init(storeId: String) {
        id = storeId
    }
    
    func didReceiveControl(_ data: CBControlData, ofType controlType: CBControlType, fromChat source: Chatterbox) {
        addOrUpdate(data)
        publishControlNotification(data, ofType: controlType, fromSource: source)
    }
    
    func didReceiveStartedTopic(_ event: StartedUserTopicMessage, fromChat source: Chatterbox) {
        ignore(action: event)
    }
    
    func retrieve(byId id: String) -> CBStorable? {
        var result: CBStorable?
        
        dataSink.forEach { item in
            if item.uniqueId() == id {
                result = item
            }
        }
        return result
    }
    
    // MARK: Notifications
    
    enum ChatNotificationType: String {
        case booleanControl = "com.servicenow.SnowChat.BooleanControl"
        case dateControl = "com.servicenow.SnowChat.DateControl"
        case inputControl = "com.servicenow.SnowChat.InputControl"
        
        case none = "com.servicenow.SnowChat.none"
    }
    
    private static func notificationNameFor(controlType: CBControlType) -> Notification.Name {
        var notificationName: String
        
        switch controlType {
        case .boolean:
            notificationName = ChatNotificationType.booleanControl.rawValue
        case .input:
            notificationName = ChatNotificationType.inputControl.rawValue
        default:
            notificationName = ChatNotificationType.none.rawValue
        }
        return Notification.Name(notificationName)
    }
    
    static func addObserver(forControl: CBControlType, source: Chatterbox?, block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
        let notificationName = notificationNameFor(controlType: forControl)
        return NotificationCenter.default.addObserver(forName: notificationName,
                                                      object: source,
                                                      queue: nil,
                                                      using: block)
    }
    
    fileprivate func publishControlNotification(_ data: CBControlData, ofType: CBControlType, fromSource source: Chatterbox) {
        let notificationName = ChatDataStore.notificationNameFor(controlType: ofType)

        let info: [String: Any] = ["state": data]
        NotificationCenter.default.post(name: notificationName,
                                        object: source,
                                        userInfo: info)
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
    
    private func ignore(action: CBActionMessageData) {
        Logger.default.logInfo("ChatDataStore ignoring action message: \(action)")
    }
}
