//
//  DebugSettings+Instance.swift
//  SnowChat
//
//  Created by Will Lisac on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// FIXME: None of this should be stored here.
// We should never store the username and password.
// Using this for initial setup / debugging only.

extension DebugSettings {
    
    private static let instanceURLKey = "DebugSettingsInstanceURL"
    private static let usernameKey = "DebugSettingsUsername"
    private static let passwordKey = "DebugSettingsPassword"
    
    var instanceURL: URL {
        get {
            if let url = UserDefaults.standard.url(forKey: DebugSettings.instanceURLKey) {
                return url
            } else {
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://demonightlychatbot.service-now.com")!
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DebugSettings.instanceURLKey)
        }
    }
    
    var username: String {
        get {
            if let username = UserDefaults.standard.string(forKey: DebugSettings.usernameKey), !username.isEmpty {
                return username
            } else {
                return "admin"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DebugSettings.usernameKey)
        }
    }
    
    var password: String {
        get {
            if let password = UserDefaults.standard.string(forKey: DebugSettings.passwordKey), !password.isEmpty {
                return password
            } else {
                return "snow2004"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DebugSettings.passwordKey)
        }
    }
    
}
