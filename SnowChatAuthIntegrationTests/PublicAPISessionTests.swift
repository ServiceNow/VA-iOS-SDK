//
//  PublicAPISessionTests.swift
//  SnowChatAuthIntegrationTests
//
//  Created by Will Lisac on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
import Alamofire

class PublicAPISessionTests: BaseAuthTestCase {
    
    // Show that it's possible to use a public REST API to set an auth cookie when providing valid auth credentials
    func testUsingPublicAPIToAuthenticate() {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let publicRESTAPI = instanceConfiguration.publicRESTAPI
        let privateRESTAPI = instanceConfiguration.privateRESTAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        
        func logIn() {
            sessionManager.request(publicRESTAPI, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.accessTokenAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    ensureSession()
            }
            .resume()
        }
        
        func ensureSession() {
            sessionManager.request(privateRESTAPI, method: .get)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    ensureSessionExpectation.fulfill()
                    print("Finished ensure session.")
            }
            .resume()
        }
        
        logIn()
        
        self.wait(for: [ensureSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 5)
    }
    
    /// This shows using a public API with invalid auth header
    /// We need some way to know that a public API is using a guest user instead of an authenticated user
    /// Tests that the old X-Is-Logged-In header shows true for guest user (which is silly)
    /// Tests that the new X-Is-Valid-Logged-In shows false for guest user (which makes sense)
    /// Why is it important to know if you're a valid user? Take this use case:
    /// Table API is a public API for public tables – but an ACL might limit your result set.
    /// So now you think you're authenticated, but you're not, and you're just getting different results. Whee!
    /// The client should be able to know if it's logged in or a guest.
    func testPublicAPIWithInvalidToken() {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let url = instanceConfiguration.publicRESTAPI
        
        let publicAPIExpectation = XCTestExpectation(description: "Public API")
        
        sessionManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.invalidAccessTokenAuthHeaders)
            .validate()
            .responseJSON { response in
                XCTAssert(response.result.isSuccess)
                let headers = response.response?.allHeaderFields ?? [:]
                let isLoggedInHeader = headers["X-Is-Logged-In"] as? String ?? ""
                let isValidLoggedInHeader = headers["X-Is-Valid-Logged-In"] as? String ?? ""
                
                XCTAssert(isLoggedInHeader == "true")
                XCTAssert(isValidLoggedInHeader == "false")
                
                publicAPIExpectation.fulfill()
                print("Finished public API call.")
        }
        .resume()
        
        self.wait(for: [publicAPIExpectation], timeout: 5)
    }
    
    /// Super simple test that shows using a public API with no auth
    /// Simply tests that the API returns successful
    func testPublicAPIWithNoAuth() {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let url = instanceConfiguration.apiURLWithPath("mobile/app_bootstrap/pre_auth")
        
        let publicAPIExpectation = XCTestExpectation(description: "Public API")
        
        sessionManager.request(url, method: .get)
            .validate()
            .responseJSON { response in
                XCTAssert(response.result.isSuccess)
                publicAPIExpectation.fulfill()
                print("Finished public API call.")
        }
        .resume()
        
        self.wait(for: [publicAPIExpectation], timeout: 5)
    }
    
}
