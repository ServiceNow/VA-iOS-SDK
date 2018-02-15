//
//  BaseAuthTestCase.swift
//  SnowChatAuthIntegrationTests
//
//  Created by Will Lisac on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
import Alamofire

// General Note: If you're seeing multiple requests after 401, be aware of this: https://github.com/Alamofire/Alamofire/issues/1694

class BaseAuthTestCase: XCTestCase {
    
    private(set) var instanceConfiguration = InstanceConfirugation()
    
    override func setUp() {
        super.setUp()
        
        if instanceConfiguration.accessToken == nil {
            setupAuthTokenIfNeeded()
        }
    }
    
    private func setupAuthTokenIfNeeded() {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let secretURL = instanceConfiguration.apiURLWithPath("mobileapp/plugin/secret")
        let oAuthURL = instanceConfiguration.urlWithPath("oauth_token.do")
        let expectation = XCTestExpectation(description: "Get Access Token")
        
        func fetchSecret() {
            sessionManager.request(secretURL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.basicAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let dictionary = response.result.value as? [String : Any] ?? [:]
                    let result = dictionary["result"] as? [String : Any] ?? [:]
                    let secret = result["secret"] as? String ?? ""
                    
                    XCTAssertFalse(secret.isEmpty)
                    
                    print("Fetched secret")
                    
                    fetchToken(secret: secret)
            }
        }
        
        func fetchToken(secret: String) {
            let params = ["grant_type" : "password",
                          "username" : instanceConfiguration.username,
                          "password" : instanceConfiguration.password,
                          "client_id" : "3e57bb02663102004d010ee8f561307a",
                          "client_secret" : secret]
            
            sessionManager.request(oAuthURL, method: .post, parameters: params, encoding: URLEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let dictionary = response.result.value as? [String : Any] ?? [:]
                    let token = dictionary["access_token"] as? String ?? ""
                    
                    XCTAssertFalse(token.isEmpty)
                    
                    self.instanceConfiguration.accessToken = token
                    
                    print("Fetched token")
                    
                    expectation.fulfill()
            }
        }
        
        fetchSecret()
        
        self.wait(for: [expectation], timeout: 20)
    }
    
}
