//
//  User.swift
//  SnowChat
//
//  Created by Will Lisac on 2/12/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct User {
    let username: String
    let sysId: String
}

extension User {
    init?(dictionary: [String : Any]) {
        guard let username = dictionary["user_name"] as? String,
            let sysId = dictionary["user_id"] as? String else {
                return nil
        }
        
        self.init(username: username, sysId: sysId)
    }
}
