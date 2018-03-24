//
//  UserDefaults+Codable.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    // Used to wrap all values so we don't encounter top level encoding issues.
    // For example, primitives like String, Int, etc, conform to Codable, but can't be used as a top level objects
    // We'll get this error without a wrapper in those cases. For example a string:
    // "Top-level Optional<T> encoded as string property list fragment"
    private struct Wrapped<T>: Codable where T: Codable {
        let value: T
    }
    
    func setCodable<T: Codable>(_ value: T?, forKey defaultName: String) {
        let wrapped = value.flatMap { Wrapped(value: $0) }
        let data = try? PropertyListEncoder().encode(wrapped)
        set(data, forKey: defaultName)
    }
    
    func decodable<T>(forKey defaultName: String, type: T.Type) -> T? where T: Codable {
        if let data = data(forKey: defaultName) {
            let wrapperType = Wrapped<T>.self
            let wrapped = try? PropertyListDecoder().decode(wrapperType, from: data)
            return wrapped?.value
        }
        return nil
    }
    
}
