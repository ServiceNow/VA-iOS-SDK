//
//  AuthManager.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/6/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

enum AuthError: LocalizedError {
    case noCredential
}

class AuthManager: NSObject {
    
    private let sessionManager = SessionManager(configuration: .ephemeral)
    
    private let instanceURL: URL
    
    init(instanceURL: URL) {
        self.instanceURL = instanceURL
    }
    
    func logIn(username: String, password: String, completion: @escaping (Result<OAuthCredential>) -> Void) {
        let oAuthAPI = instanceURL.appendingPathComponent("oauth_token.do")
        
        // ServiceNow Virtual Agent Example App OAuth Entity
        let clientId = "2c403f19ac901300b303eef6c8b842d3"
        let clientSecret = "H&g(T!4<6Y"
        
        let params = ["grant_type" : "password",
                      "username" : username,
                      "password" : password,
                      "client_id" : clientId,
                      "client_secret" : clientSecret]
        
        sessionManager.request(oAuthAPI, method: .post, parameters: params, encoding: URLEncoding.default)
            .validate()
            .responseJSON { response in
                if let error = response.error {
                    completion(.failure(error))
                    return
                }
                
                let dictionary = response.result.value as? [String : Any] ?? [:]
                guard let credential = OAuthCredential(dictionary: dictionary) else {
                    completion(.failure(AuthError.noCredential))
                    return
                }
                
                completion(.success(credential))
        }
    }
    
}
