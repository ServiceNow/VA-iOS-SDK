//
//  InstanceSettings.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

// FIXME: Store OAuth credential in the keychain.
// Using this for quick setup of the framework container app.

class InstanceSettings {

    static let shared = InstanceSettings()
    
    private init() { }
    
    private static let instanceURLKey = "InstanceSettingsInstanceURL"
    private static let credentialKey = "InstanceSettingsCredential"
    private static let authProviderKey = "InstanceSettingsAuthProviderStringMapped"
    
    private let defaults = UserDefaults.standard
    
    var instanceURL: URL? {
        get {
            return defaults.url(forKey: InstanceSettings.instanceURLKey)
        }
        set {
            defaults.set(newValue, forKey: InstanceSettings.instanceURLKey)
            defaults.synchronize()
        }
    }
    
    var credential: OAuthCredential? {
        get {
            return defaults.decodable(forKey: InstanceSettings.credentialKey, type: OAuthCredential.self)
        }
        set {
            defaults.setCodable(newValue, forKey: InstanceSettings.credentialKey)
            defaults.synchronize()
        }
    }
    
    var authProvider: AuthProvider? {
        get {
            return defaults.decodable(forKey: InstanceSettings.authProviderKey, type: AuthProvider.self)
        }
        set {
            defaults.setCodable(newValue, forKey: InstanceSettings.authProviderKey)
            defaults.synchronize()
        }
    }
    
}
