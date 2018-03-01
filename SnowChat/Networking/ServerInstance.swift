//
//  ServerInstance.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

internal class ServerInstance: NSObject {
    
    let instanceURL: URL
    
    public init(instanceURL: URL) {
        self.instanceURL = instanceURL
    }
    
    func isValidInstanceURL(_ url: URL) -> Bool {
        guard let host = url.host, let instanceHost = instanceURL.host else {
            return false
        }
        return host.lowercased() == instanceHost.lowercased()
    }
    
}
