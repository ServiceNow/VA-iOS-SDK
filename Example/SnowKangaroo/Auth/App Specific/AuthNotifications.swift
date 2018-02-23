//
//  AuthNotifications.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension Notification.Name {
    // Posted when the current ServiceNow authentication becomes invalid
    static let SNAuthenticationDidBecomeInvalid = Notification.Name("com.servicenow.snowKangaroo.notification.name.authenticationDidBecomeInvalid")
    
    // Posted when the current ServiceNow authentication becomes valid
    // This happens after log in or after refreshing an auth token
    static let SNAuthenticationDidBecomeValid = Notification.Name("com.servicenow.snowKangaroo.notification.name.authenticationDidBecomeValid")
    
    // Posted when the application should explicitly log the user out
    static let LogOut = Notification.Name("com.servicenow.snowKangaroo.notification.name.logOut")
}
