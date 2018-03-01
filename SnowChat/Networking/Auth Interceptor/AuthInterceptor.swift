//
//  AuthInterceptor.swift
//  SnowChat
//
//  Created by Will Lisac on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

/// The auth interceptor class is responsible for adding auth headers and for retrying user token challenges
class AuthInterceptor: RequestAdapter, RequestRetrier {
    
    private let instance: ServerInstance
    private let token: OAuthToken
    
    private var userToken: String?
    private let userTokenQueue = DispatchQueue(label: "com.servicenow.snowChat.authInterceptor.userTokenQueue", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init(instance: ServerInstance, token: OAuthToken) {
        self.token = token
        self.instance = instance
    }
    
    // MARK: - RequestAdapter
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        // Only authenticate instance requests
        guard let url = urlRequest.url, instance.isValidInstanceURL(url) else { return urlRequest }
        
        var urlRequest = urlRequest
        
        // Set current auth header on the request
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: HTTPHeaderField.authorization)
        
        // This enables us to be authenticated with a session cookie even if the oauth token has expired
        urlRequest.setValue(String(true), forHTTPHeaderField: HTTPHeaderField.authorizeByCookieFirst)
        
        // Prefer end user session
        urlRequest.setValue(String(true), forHTTPHeaderField: HTTPHeaderField.endUser)
        
        // Set current user token on the request
        userTokenQueue.sync {
            if let userToken = userToken {
                urlRequest.setValue(userToken, forHTTPHeaderField: HTTPHeaderField.userToken)
            }
        }
        
        return urlRequest
    }
    
    // MARK: - RequestRetrier
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        // Only retry once
        guard request.retryCount == 0 else {
            completion(false, 0)
            return
        }
        
        // Only retry instance requests
        guard let urlRequest = request.request, let url = urlRequest.url, instance.isValidInstanceURL(url) else {
            completion(false, 0)
            return
        }
        
        // Only retry user token challenges via 401s
        guard let response = request.response, response.statusCode == 401,
            let userTokenResponse = response.userTokenResponse, response.shouldResubmitUserToken else {
                completion(false, 0)
                return
        }
        
        userTokenQueue.async(flags: .barrier) { [weak self] in
            self?.userToken = userTokenResponse
        }
        
        completion(true, 0)
    }
    
}
