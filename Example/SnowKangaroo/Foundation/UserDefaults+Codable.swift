//
//  UserDefaults+Codable.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    func setCodable<T: Codable>(_ value: T?, forKey defaultName: String) {
        let data = try? PropertyListEncoder().encode(value)
        set(data, forKey: defaultName)
    }
    
    func decodable<T>(forKey defaultName: String, type: T.Type) -> T? where T: Decodable {
        if let data = data(forKey: defaultName) {
            return try? PropertyListDecoder().decode(type, from: data)
        }
        return nil
    }
    
}
