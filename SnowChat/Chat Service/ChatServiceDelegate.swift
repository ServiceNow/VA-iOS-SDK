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
}

protocol ChatServiceDelegate: AnyObject {
    
    // called to get user credentials for the chat session
    func userCredentials() -> ChatUserCredentials
    
    // credentials provided failed to authorize user. Return true if authorization should be retried,
    // which will cause userCredentials to be called again. Returning false will not retry, and chat
    // client will be invalid (fatalError delegate method will be called)
    func authorizationFailed() -> Bool
    
    // Chat Client has encountered a fatal error and must be ended
    func fatalError()
}
