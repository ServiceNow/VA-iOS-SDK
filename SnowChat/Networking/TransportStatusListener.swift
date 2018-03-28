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
    func apiManagerTransportDidBecomeUnavailable(_ apiManager: APIManager)

    // transport is being reconnected
    func apiManagerTransportIsReconnecting(_ apiManager: APIManager)

    // transport available means AMB and REST can be called
    func apiManagerTransportDidBecomeAvailable(_ apiManager: APIManager)
    
    // user authentication did become invalid, need to get new token
    func apiManagerAuthenticationDidBecomeInvalid(_ apiManager: APIManager)
    
}
