//
//  ActionMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct ActionMessage: Codable {
    let type: String
    let data: ActionMessageData<ActionMessageWrapper>
    
    struct ActionMessageWrapper: Codable {
        let type: String
    }
}
