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
            if let data = defaults.data(forKey: InstanceSettings.credentialKey),
                let credential = try? PropertyListDecoder().decode(OAuthCredential.self, from: data) {
                return credential
            }
            return nil
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            defaults.set(data, forKey: InstanceSettings.credentialKey)
            defaults.synchronize()
        }
    }
    
    var authProvider: AuthProvider? {
        // FIXME: Enums and codable conformance are a bit involved
        // Using simple string persistence solution to get started
        get {
            guard let stringValue = defaults.string(forKey: InstanceSettings.authProviderKey) else {
                return nil
            }
            switch stringValue {
            case "openID":
                return .openID
            case "local":
                return .local
            default:
                return nil
            }
        }
        set {
            let newStringValue: String? = newValue.flatMap { authProvider in
                switch authProvider {
                case .openID:
                    return "openID"
                case .local:
                    return "local"
                }
            }
            
            defaults.set(newStringValue, forKey: InstanceSettings.authProviderKey)
            defaults.synchronize()
        }
    }
    
}
