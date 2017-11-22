//
//  ServerInstance.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class ServerInstance: NSObject {
    
    let instanceURL: URL
    
    init(instanceURL: URL) {
        self.instanceURL = instanceURL
    }
    
}
