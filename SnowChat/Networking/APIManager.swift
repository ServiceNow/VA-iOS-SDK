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
    
    enum APIManagerError: Error {
        case loginError(message: String)
    }
    
    // FIXME: Support actual log in methods
    
    func logIn(username: String, password: String, completionHandler: @escaping (Error?) -> Void) {
        sessionManager.adapter = AuthHeadersAdapter(username: username, password: password)
        
        // FIXME: Don't construct URLs by hand. Need to define a new pattern in this project similar to SN iOS app.
        let authURL = instance.instanceURL.appendingPathComponent("/api/now/mobile/app_bootstrap/post_auth")
        
        sessionManager.request(authURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { [weak self] response in
            guard let strongSelf = self else { return }
            
            let requestSuccessful = response.result.isSuccess
            var isSuccess = true
            var loginError: APIManagerError?
            
            // success in GET does not mean successful login - have to check the response
            if requestSuccessful {
                if let value = response.value as? [String: Any] {
                    if let error = value["error"] as? [String: Any] {
                        isSuccess = false
                        let msg = error["message"] as? String ?? error.debugDescription
                        loginError = APIManagerError.loginError(message: msg)
                    }
                }
            } else {
                isSuccess = false
            }
            
            if isSuccess {
                strongSelf.ambClient.connect()
            }

            completionHandler(isSuccess ? nil : loginError)
        }
    }
    
}
