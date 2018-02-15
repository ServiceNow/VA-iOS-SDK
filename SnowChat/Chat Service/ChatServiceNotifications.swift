//
//  ChatServiceNotifications.swift
//  SnowChat
//
//  Created by Will Lisac on 2/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension Notification.Name {
    public struct ChatService {
        public static let AuthenticationDidBecomeInvalid = Notification.Name("com.servicenow.snowChat.notification.name.chatService.authenticationDidBecomeInvalid")
    }
}
