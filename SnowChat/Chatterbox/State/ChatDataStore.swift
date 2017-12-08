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
    
    func didReceiveBooleanControl(_ data: BooleanControlMessage, fromChat source: Chatterbox) {
        addOrUpdate(data)
        publishBooleanControlNotification(data, fromSource: source)
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
    
    static func addObserver(forControl: CBControlType, source: Chatterbox?, block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
        var notificationName: String
        
        switch forControl {
        case .boolean:
            notificationName = ChatNotificationType.booleanControl.rawValue
        default:
            notificationName = ChatNotificationType.none.rawValue
        }
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: notificationName),
                                                      object: source,
                                                      queue: nil,
                                                      using: block)
    }
    
    fileprivate func publishBooleanControlNotification(_ data: BooleanControlMessage, fromSource source: Chatterbox ) {
        let info: [String: Any] = ["state": data]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ChatNotificationType.booleanControl.rawValue),
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
