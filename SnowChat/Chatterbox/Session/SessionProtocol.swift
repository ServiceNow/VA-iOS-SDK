//
//  SessionProtocol.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol ManageSessions {
    
    func createSession(userId: String, userToken: String) -> CBSession
    func getSession(sessionId: String) -> CBSession
    func refreshSession(_ session: CBSession) -> CBSession
    func destroySession(sessionId: String) -> Bool
}
