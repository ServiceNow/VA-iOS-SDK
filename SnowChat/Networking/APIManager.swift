//
//  APIManager.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire
import AMBClient

class APIManager: NSObject {
    
    private let instance: ServerInstance
    private let sessionManager = SessionManager()
    
    internal let ambClient: AMBClient
    
    init(instance: ServerInstance) {
        self.instance = instance
        
        ambClient = AMBClient(sessionManager: sessionManager, baseURL: instance.instanceURL)
    }
    
    // FIXME: Support actual log in methods
    
    func logIn(username: String, password: String, completionHandler: @escaping (Bool) -> Void) {
        sessionManager.adapter = AuthHeadersAdapter(username: username, password: password)
        
        // FIXME: Don't construct URLs by hand. Need to define a new pattern in this project similar to SN iOS app.
        let authURL = instance.instanceURL.appendingPathComponent("/api/now/mobile/app_bootstrap/post_auth")
        
        sessionManager.request(authURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { [weak self] response in
            guard let strongSelf = self else { return }
            
            let isSuccess = response.result.isSuccess
            
            if isSuccess {
                strongSelf.ambClient.connect()
            }
            
            completionHandler(isSuccess)
        }
    }
    
}
