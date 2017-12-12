//
//  ChatServiceAppDelegate.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ChatUserCredentials {
    var userName: String
    var userPassword: String
    
    var vendorId: String
    var consumerId: String
    var consumerAccountId: String
}

protocol ChatServiceAppDelegate: AnyObject {
    
    func userCredentials() -> ChatUserCredentials
}
