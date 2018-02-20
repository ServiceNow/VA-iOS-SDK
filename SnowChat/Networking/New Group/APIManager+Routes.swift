//
//  APIManager+Routes.swift
//  SnowChat
//
//  Created by Will Lisac on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// TODO: Build an enum based router with known routes

extension APIManager {
    
    func apiURLWithPath(_ path: String, version: Int = 1) -> URL {
        return instance.instanceURL.appendingPathComponent("/api/now/v\(version)").appendingPathComponent(path)
    }
    
}
