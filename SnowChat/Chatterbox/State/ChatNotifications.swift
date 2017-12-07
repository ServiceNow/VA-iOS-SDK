//
//  ChatNotifications.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

enum ChatNotification: String {
    
    case booleanControl = "com.servicenow.SnowChat.BooleanControl"
    case dateControl = "com.servicenow.SnowChat.DateControl"
    case inputControl = "com.servicenow.SnowChat.InputControl"

    static func name(forKind: ChatNotification) -> Notification.Name { return Notification.Name(forKind.rawValue) }
}
