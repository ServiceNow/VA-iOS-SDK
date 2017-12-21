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
    internal let sessionManager = SessionManager()
    
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
        
        sessionManager.request(authURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil)
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
