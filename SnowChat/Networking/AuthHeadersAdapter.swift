//
//  AuthHeadersAdapter.swift
//  SnowChat
//
//  Created by Will Lisac on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

class AuthHeadersAdapter: RequestAdapter {
    
    private let accessToken: String
    private let instanceURL: URL
    
    init(instanceURL: URL, accessToken: String) {
        self.accessToken = accessToken
        self.instanceURL = instanceURL
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        
        // Only add auth headers for requests to the instance
        guard let requestHost = urlRequest.url?.host,
            let instanceHost = instanceURL.host,
            requestHost.lowercased() == instanceHost.lowercased() else {
                return urlRequest
        }
        
        var urlRequest = urlRequest
        
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // This enables us to be authenticated with a session cookie even if the access token has expired
        urlRequest.setValue("true", forHTTPHeaderField: "X-AuthorizeByCookieFirst")
        
        return urlRequest
    }
    
}
