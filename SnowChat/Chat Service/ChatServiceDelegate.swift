//
//  ChatServiceDelegate.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public protocol ChatServiceDelegate: AnyObject {
    
    // Indicates that the chat service's user authentication did become invalid
    func chatServiceAuthenticationDidBecomeInvalid(_ chatService: ChatService)
    
}
