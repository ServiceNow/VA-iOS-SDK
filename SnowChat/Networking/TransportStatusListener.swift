//
//  TransportStatusListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/30/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

protocol TransportStatusListener: AnyObject {
    
    func transportDidBecomeUnavailable()
    func transportDidBecomeAvailable()
    
    func authorizationFailure()
}
