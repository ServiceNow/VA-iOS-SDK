//
//  OAuthManager.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

enum OAuthError: LocalizedError {
    case noCredential
}

class OAuthManager: NSObject {
    
    private let sessionManager = SessionManager(configuration: .ephemeral)
    
    private let configuration: OAuthManagerConfiguration
    
    // MARK: - Initialization
    
    init(configuration: OAuthManagerConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Log In
    
    func authenticate(username: String, password: String, completion: @escaping (Result<OAuthCredential>) -> Void) {
        let parameters = ["grant_type" : "password",
                          "username" : username,
                          "password" : password]
        
        authenticate(parameters: parameters, completion: completion)
    }
    
    func authenticate(refreshToken: String, completion: @escaping (Result<OAuthCredential>) -> Void) {
        let parameters = ["grant_type" : "refresh_token",
                          "refresh_token" : refreshToken]
        
        authenticate(parameters: parameters, completion: completion)
    }
    
    private func authenticate(parameters: Parameters, completion: @escaping (Result<OAuthCredential>) -> Void) {
        let tokenURL = configuration.tokenURL
        
        var parameters = parameters
        parameters["client_id"] = configuration.clientId
        parameters["client_secret"] = configuration.clientSecret
        
        if let scope = configuration.defaultScope {
            parameters["scope"] = scope
        }
        
        sessionManager.request(tokenURL, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .validate()
            .responseJSON { response in
                if let error = response.error {
                    completion(.failure(error))
                    return
                }
                
                let dictionary = response.result.value as? [String : Any] ?? [:]
                
                guard let credential = OAuthCredential(dictionary: dictionary) else {
                    completion(.failure(OAuthError.noCredential))
                    return
                }
                
                completion(.success(credential))
        }
        
    }
    
}
