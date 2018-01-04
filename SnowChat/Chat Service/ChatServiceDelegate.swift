//
//  ChatServiceDelegate.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ChatUserCredentials {
    var username: String
    var password: String
    
    var vendorId: String
    var consumerId: String
    var consumerAccountId: String
}

protocol ChatServiceDelegate: AnyObject {
    
    func userCredentials() -> ChatUserCredentials
}
