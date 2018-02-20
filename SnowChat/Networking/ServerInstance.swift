//
//  ServerInstance.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public class ServerInstance: NSObject {
    
    let instanceURL: URL
    
    public init(instanceURL: URL) {
        self.instanceURL = instanceURL
    }
    
}
