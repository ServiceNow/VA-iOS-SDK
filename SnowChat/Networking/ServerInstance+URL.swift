//
//  ServerInstance+URL.swift
//  SnowChat
//
//  Created by Will Lisac on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// Some basic instance URL parsing from user input
// See legacy NOWServerInstance for more "advanced" sanitization options
// https://gitlab-deo.devsnc.com/mobile/servicenow-ios/blob/development/NOWAPIKit/NOWAPIKit/Network/NOWServerInstance.m

extension ServerInstance {
    
    internal static func instanceURL(fromUserInput input: String) -> URL? {
        guard !input.isEmpty else { return nil }
        
        var urlString: String
        
        // Try to detect a simple instance name
        if input.contains(".") || input.contains(":") {
            urlString = input
        } else {
            urlString = "https://" + input + ".service-now.com"
        }
        
        // Try to add appropriate http or https scheme if needed
        if !urlString.hasPrefix("http") {
            if urlString.contains(".local:") || urlString.contains("localhost:") {
                urlString = "http://" + urlString
            } else {
                urlString = "https://" + urlString
            }
        }
        
        return URL(string: urlString)
    }
    
}
