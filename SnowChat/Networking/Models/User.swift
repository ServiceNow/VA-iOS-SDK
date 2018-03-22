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
        guard let username = dictionary["user_name"] as? String, !username.isEmpty,
            let sysId = dictionary["user_sys_id"] as? String, !sysId.isEmpty else {
                return nil
        }
        
        self.init(username: username, sysId: sysId)
    }
}
