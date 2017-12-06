//
//  SessionProtocol.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol ManageSessions {
    
    func createSession(userId: String, userToken: String, completionHandler: @escaping (CBSession?) -> Void)
    func getSession(sessionInfo: CBSession, completionHandler: @escaping (CBSession?) -> Void)
    func refreshSession(_ session: CBSession, completionHandler: @escaping (CBSession?) -> Void)
    func destroySession(sessionId: String, completionHandler: @escaping (Bool) -> Void)
}
