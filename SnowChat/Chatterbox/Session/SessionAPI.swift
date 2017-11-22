//
//  SessionAPI.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/22/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class SessionAPI {
    
    // TODO: add HTTP rest support for session calls
    
    func getSession(sessionInfo: CBSession) -> CBSession {
        var resultSession = CBSession(clone: sessionInfo)
        
        // TODO: create the session
        resultSession.sessionState = .opened
        
        return resultSession
    }
    
    func suggestTopics(searchText: String) -> [CBTopic] {
        
        return [CBTopic]()
    }
    
    func allTopics() -> [CBTopic] {
        return suggestTopics(searchText: "")
    }
}
