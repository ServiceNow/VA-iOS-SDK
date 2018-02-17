//
//  SessionTimeoutTests.swift
//  SnowChatAuthIntegrationTests
//
//  Created by Will Lisac on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
import Alamofire

class SessionTimeoutTests: BaseAuthTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// Shows that we can use an access token to get an integration session cookie
    /// and that the session will timeout after a minute.
    /// Assumes a 1 minute integration session.
    func testIntegrationSessionExpiration() {
        
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let url = instanceConfiguration.privateRESTAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        let esnureExpiredSessionExpectation = XCTestExpectation(description: "Ensure expired session")
        
        func logIn() {
            sessionManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.accessTokenAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    ensureSession()
            }
        }
        
        func ensureSession() {
            sessionManager.request(url, method: .get)
                .validate()
                .response { (response) in
                    ensureSessionExpectation.fulfill()
                    print("Finished ensure session.")
                    ensureExpiredSessionAfterDelay()
            }
        }
        
        func ensureExpiredSessionAfterDelay() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 70) {
                
                sessionManager.request(url, method: .get)
                    .validate()
                    .responseJSON { response in
                        XCTAssert(response.result.isFailure)
                        esnureExpiredSessionExpectation.fulfill()
                        print("Finished ensure expired session.")
                }
                
            }
        }
        
        logIn()
        
        self.wait(for: [esnureExpiredSessionExpectation], timeout: 100)
        self.wait(for: [ensureSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 5)
    }
    
    /// Shows that we can use an access token to get an integration session cookie.
    /// We can then "upgrade" that integration session to a UI session by requesting a URL that's considered a "UI type".
    /// We will verify that the session is still valid beyond the integration session, but not valid after the UI session expires.
    /// Note that we also need to get a CSRF. This also serves as validation that we ended up with a UI Session:
    /// This is because REST APIs require a CSRF token if you're authenticating _only_ with a cookie that's considered a UI session (which we are here).
    /// See `doCsrfCheckIfNeeded()` in `RESTAPIProcessor.java` in Glide.
    /// Assumes a 1 minute integration session.
    /// Assumes a 2 minute UI session.
    // swiftlint:disable:next function_body_length
    func testUISessionUpgradeAndExpiration() {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let privateRESTAPI = instanceConfiguration.privateRESTAPI
        let privateUIAPI = instanceConfiguration.privateUIAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let uiSessionExpectation = XCTestExpectation(description: "Upgrade to UI session")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        let esnureExpiredSessionExpectation = XCTestExpectation(description: "Ensure expired session")
        
        func logIn() {
            sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.accessTokenAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    ensureUISession()
            }
        }
        
        func ensureUISession() {
            sessionManager.request(privateUIAPI, method: .get)
                .validate()
                .responseString { (response) in
                    XCTAssert(response.result.isSuccess)
                    uiSessionExpectation.fulfill()
                    print("Upgraded to UI session.")
                    fetchCSRF()
            }
        }
        
        func fetchCSRF() {
            // Warning that this will auto retry and the NSURLSession layer due to an auth challenge.
            // It's only called once. If you noticed that in Charles logs, ignore it.
            sessionManager.request(privateRESTAPI, method: .get)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isFailure)
                    let newToken = response.response?.allHeaderFields["X-UserToken-Response"] as? String ?? ""
                    XCTAssertFalse(newToken.isEmpty)
                    print("Got CSRF token.")
                    ensureSessionStillValidAfterIntegrationSessionTimeout(csrf: newToken)
                }
        }
        
        func ensureSessionStillValidAfterIntegrationSessionTimeout(csrf: String) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 70) {
                
                let csrfHeader = ["X-UserToken" : csrf]
                sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: csrfHeader)
                    .validate()
                    .responseJSON { response in
                        XCTAssert(response.result.isSuccess)
                        ensureSessionExpectation.fulfill()
                        print("Finished ensure valid session after delay.")
                        ensureExpiredSessionAfterUISessionTimeout(csrf: csrf)
                }
                
            }
        }
        
        func ensureExpiredSessionAfterUISessionTimeout(csrf: String) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 130) {
                
                let csrfHeader = ["X-UserToken" : csrf]
                sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: csrfHeader)
                    .validate()
                    .responseString { (response) in
                        XCTAssert(response.result.isFailure)
                        XCTAssertNotNil(response.response)
                        esnureExpiredSessionExpectation.fulfill()
                        print("Finished ensure expired session.")
                }
                
            }
        }
        
        logIn()
        
        self.wait(for: [esnureExpiredSessionExpectation], timeout: 230)
        self.wait(for: [ensureSessionExpectation], timeout: 100)
        self.wait(for: [uiSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 5)
    }
    
    /// This attempts to upgrade an integration session to a UI session using an angular processor.
    /// **This is currently failing**
    /// I'd like to understand why angular.do doesn't convert us to a UI session
    /// Maybe it's because it's AJAX and not UI type – but don't both of these count as UI sessions?
    /// Need to check with Floyd.
    // swiftlint:disable:next function_body_length
    func testUISessionUpgradeWithAngularProcessorAndExpiration() {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let privateRESTAPI = instanceConfiguration.privateRESTAPI
        let privateUIAPI = instanceConfiguration.privateUIAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let uiSessionExpectation = XCTestExpectation(description: "Upgrade to UI session")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        let esnureExpiredSessionExpectation = XCTestExpectation(description: "Ensure expired session")
        
        func logIn() {
            sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.accessTokenAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    fetchCSRF()
            }
        }
        
        func fetchCSRF() {
            let processorURL = instanceConfiguration.angularAPI
            let params = ["sysparm_type" : "get_user"]
            
            sessionManager.request(processorURL, method: .get, parameters: params)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isFailure)
                    let newToken = response.response?.allHeaderFields["X-UserToken-Response"] as? String ?? ""
                    XCTAssertFalse(newToken.isEmpty)
                    print("Got CSRF token.")
                    ensureSession(csrf: newToken)
            }
        }
        
        func ensureSession(csrf: String) {
            let processorURL = instanceConfiguration.angularAPI
            let params = ["sysparm_type" : "get_user"]
            
            let csrfHeader = ["X-UserToken" : csrf]
            sessionManager.request(processorURL, method: .get, parameters: params, encoding: URLEncoding.default, headers: csrfHeader)
                .validate()
                .responseString { response in
                    XCTAssert(response.result.isSuccess)
                    uiSessionExpectation.fulfill()
                    print("Finished ensure session.")
                    
                    ensureSessionStillValidAfterIntegrationSessionTimeout(csrf: csrf)
            }
        }
        
        func ensureSessionStillValidAfterIntegrationSessionTimeout(csrf: String) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 70) {
                
                let csrfHeader = ["X-UserToken" : csrf]
                sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: csrfHeader)
                    .validate()
                    .responseJSON { response in
                        XCTAssert(response.result.isSuccess)
                        ensureSessionExpectation.fulfill()
                        print("Finished ensure valid session after delay.")
                        ensureExpiredSessionAfterUISessionTimeout(csrf: csrf)
                }
                
            }
        }
        
        func ensureExpiredSessionAfterUISessionTimeout(csrf: String) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 130) {
                
                let csrfHeader = ["X-UserToken" : csrf]
                sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: csrfHeader)
                    .validate()
                    .responseString { (response) in
                        XCTAssert(response.result.isFailure)
                        XCTAssertNotNil(response.response)
                        esnureExpiredSessionExpectation.fulfill()
                        print("Finished ensure expired session.")
                }
                
            }
        }
        
        logIn()
        
        self.wait(for: [esnureExpiredSessionExpectation], timeout: 230)
        self.wait(for: [ensureSessionExpectation], timeout: 100)
        self.wait(for: [uiSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 5)
    }
    
}
