//
//  ChatService.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public class ChatService {
    
    private let chatterbox = Chatterbox(dataListener: nil, eventListener: nil)
    
    public func chatViewController(modal: Bool) -> ChatViewController {
        if modal {
            // FIXME: Handle modal case
            fatalError("Not yet implemented.")
        }
        return ChatViewController(chatterbox: chatterbox)
    }
    
}
