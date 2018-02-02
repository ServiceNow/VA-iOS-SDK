//
//  TransportStatusListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/30/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

protocol TransportStatusListener: AnyObject {
    
    // transport is not available means no AMB and no REST calls
    func transportDidBecomeUnavailable()
    
    // transport available means AMB and REST can be called
    func transportDidBecomeAvailable()
    
    // credentials are invalid, need to get new ones from the app
    func authorizationFailure()
}
