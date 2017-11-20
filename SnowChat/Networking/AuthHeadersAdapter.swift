//
//  AuthHeadersAdapter.swift
//  SnowChat
//
//  Created by Will Lisac on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

// FIXME: Remove this. Added basic auth to get us up and running.

class AuthHeadersAdapter: RequestAdapter {
    
    let authValue: String
    
    init(username: String, password: String) {
        let credentials = "\(username):\(password)"
        let data = credentials.data(using: .utf8)
        let base64Auth = data?.base64EncodedString() ?? ""
        authValue = "Basic \(base64Auth)"
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        
        urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
}
