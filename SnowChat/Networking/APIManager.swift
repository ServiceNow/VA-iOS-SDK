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
    
    internal let instance: ServerInstance
    
    // Each API Manager instance has a private session. That's why we use an ephemeral configuration.
    internal let sessionManager = SessionManager(configuration: .ephemeral)
    
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
        
        sessionManager.request(apiURLWithPath("mobile/app_bootstrap/post_auth"),
                               method: .get,
                               parameters: nil,
                               encoding: JSONEncoding.default,
                               headers: nil)
            .validate()
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                
                var loginError: APIManagerError?
                
                switch response.result {
                case .success:
                    strongSelf.ambClient.connect()
                case .failure(let error):
                    loginError = APIManagerError.loginError(message: "Login failed: \(error.localizedDescription)")
                }
                completionHandler(loginError)
        }
    }
    
}
