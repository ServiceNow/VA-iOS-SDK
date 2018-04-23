//
//  AMBSessionTests.swift
//  SnowChatAuthIntegrationTests
//
//  Created by Will Lisac on 2/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
import Alamofire

class AMBSessionTests: BaseAuthTestCase {
    
    /// This tests documents a bug in AMB's session status
    /// The test currently fails when it finds the bug
    /// If this test passes, it didn't find the bug or it's been fixed. Yay!
    
    /// This shows that AMB will change the "glide.session.status" from "session.logged.out" to "session.logged.in"
    /// just by sending a message over AMB. This shouldn't happen, but it almost always does after several back and forths.
    /// To make things more interesting, this doesn't happen with all channels.
    /// I've only see it happen on the /cs/messages/{id} channel, for example: /cs/messages/C3E4C47D16AC4B8ABB424F59B7C29FF3
    /// and I've never seen it happen on record watcher channel, for example: /rw/default/incident/T1JERVJCWW51bWJlcg--
    
    /// TODO: What happens if we do an ajax call or something to get user activity since REST (at least the time of writing) doesn't count as initial activity?
    
    /// This one fails and shows the bug
    func testAMBSessionStatusFlippingWithQlueMessageChannel() {
        let ambChannel = "/cs/messages/C3E4C47D16AC4B8ABB424F59B7C29FF3"
        testAMBSessionStatusFlipping(ambChannel: ambChannel)
    }
    /// This one passes and doesn't flip the session to logged in
    /// TODO: I have a guess – maybe it's because AMB doesn't echo the message you send back to you like chat does?
    /// You should explore that more.
    func testAMBSessionStatusFlippingWithRecordWatcher() {
        // active incidents channel
        let ambChannel = "/rw/default/incident/T1JERVJCWW51bWJlcg--"
        testAMBSessionStatusFlipping(ambChannel: ambChannel)
    }
    
    // swiftlint:disable:next function_body_length
    func testAMBSessionStatusFlipping(ambChannel: String) {
        
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let privateRESTAPI = instanceConfiguration.privateRESTAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        let handshakeExpectation = XCTestExpectation(description: "AMB handshake")
        let connectLoopFinishedExpectation = XCTestExpectation(description: "AMB connect")
        
        // Get session cookie via access token headers
        func logIn() {
            sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: instanceConfiguration.accessTokenAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    ensureSession()
            }
            .resume()
        }
        
        // Verify cookie works
        func ensureSession() {
            sessionManager.request(privateRESTAPI, method: .get)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    ensureSessionExpectation.fulfill()
                    print("Finished ensure session.")
                    
                    handshake()
            }
            .resume()
        }
        
        // Setup the AMB dance!
        var ambClientId: String?
        var ambCount = 0
        var sessionStatusHasEverBeenLoggedOut = false
        var maxNumberOfAMBCalls = 20
        
        func handshake() {
            let url = instanceConfiguration.urlWithPath("amb/handshake")
            let params: Parameters = ["supportedConnectionTypes": ["long-polling"],
                                      "id": ambCount,
                                      "channel": "/meta/handshake",
                                      "minimumVersion": "1.0beta",
                                      "version": "1.0"]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let array = response.result.value as? [Any] ?? []
                    let dictionary = array.first as? [String : Any] ?? [:]
                    let clientId = dictionary["clientId"] as? String ?? ""
                    let success = dictionary["successful"] as? Bool ?? false
                    
                    XCTAssertTrue(success)
                    XCTAssertFalse(clientId.isEmpty)
                    
                    ambClientId = clientId
                    
                    handshakeExpectation.fulfill()
                    print("Finished handshake.")
                    subscribe()
            }
            .resume()
        }
        
        // Subscribe to the AMB channel
        // TODO: Try removing the subscribe and see if it still happens?
        func subscribe() {
            ambCount += 1
            
            let url = instanceConfiguration.urlWithPath("amb")
            let params: Parameters = ["subscription": ambChannel,
                                      "channel": "/meta/subscribe",
                                      "id": ambCount,
                                      // swiftlint:disable:next force_unwrapping
                                      "clientId": ambClientId!]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let array = response.result.value as? [Any] ?? []
                    let dictionary = array.first as? [String : Any] ?? [:]
                    let success = dictionary["successful"] as? Bool ?? false
                    
                    XCTAssertTrue(success)
                    
                    print("Finished subscribe.")
                    connect()
            }
            .resume()
        }
        
        func connect() {
            ambCount += 1
            
            let url = instanceConfiguration.urlWithPath("amb/connect")
            let params: Parameters = ["id": ambCount,
                                      // swiftlint:disable:next force_unwrapping
                                      "clientId": ambClientId!,
                                      "channel": "/meta/connect",
                                      "connectionType": "long-polling"]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    print("Finished connect.")
                    
                    let messages = response.result.value as? [[String : Any]] ?? []
                    let sessionStatues: [String] = messages.flatMap({ (message) in
                        let ext = message["ext"] as? [String : Any]
                        let sessionStatus = ext?["glide.session.status"] as? String
                        return sessionStatus
                    })
                    
                    if sessionStatusHasEverBeenLoggedOut && sessionStatues.contains("session.logged.in") {
                        // We shouldn't be logged back in if we've ever logged out.
                        // This is the bug I've seen.
                        XCTFail("Detected session logged in after being logged out. Failing test.")
                        
                        // Fulfill early to kill the loop. You can remove this line to keep the loop going.
                        connectLoopFinishedExpectation.fulfill()
                    }
                    
                    guard !sessionStatues.contains("session.logged.out") else {
                        sessionStatusHasEverBeenLoggedOut = true
                        
                        // If we get logged out, try and publish a message to trigger the bug.
                        // Feel free to adjust this delay – it seems to happen regardless.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0, execute: {
                            publishMessage()
                        })
                        
                        return
                    }
                    
                    if ambCount < maxNumberOfAMBCalls {
                        connect()
                    } else {
                        connectLoopFinishedExpectation.fulfill()
                    }
            }
            .resume()
        }
        
        func publishMessage() {
            ambCount += 1
            
            // Publish some message to trigger activity
            
            let url = instanceConfiguration.urlWithPath("amb")
            let params: Parameters = ["data": ["junk" : "whatever"],
                                      "channel": ambChannel,
                                      "id": ambCount,
                                      // swiftlint:disable:next force_unwrapping
                                      "clientId": ambClientId!]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let array = response.result.value as? [Any] ?? []
                    let dictionary = array.first as? [String : Any] ?? [:]
                    let success = dictionary["successful"] as? Bool ?? false
                    
                    XCTAssertTrue(success)
                    
                    print("Finished publish.")
                    
                    if ambCount < maxNumberOfAMBCalls {
                        connect()
                    } else {
                        connectLoopFinishedExpectation.fulfill()
                    }
            }
            .resume()
        }
        
        logIn()
        
        self.wait(for: [connectLoopFinishedExpectation], timeout: 1000)
        self.wait(for: [handshakeExpectation], timeout: 20)
        self.wait(for: [ensureSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 5)
    }
    
    /// AMB does not count REST as activity by default
    /// This test shows that you can have REST traffic opt-in to count as user activity using a header
    /// See STRY5186037 for details
    /// Without this header the initial session status will be null, with this header it will be logged.in
    /// Authenticated REST -> Handshake -> Connect results in null glide session status or logged.in session status
    func testAMBCountingRESTAsActivityWithOptInHeader() {
        testAMBCountingRESTAsActivity(includeHeader: true)
    }
    
    func testAMBNotCountingRESTAsActivity() {
        testAMBCountingRESTAsActivity(includeHeader: false)
    }
    
    // swiftlint:disable:next function_body_length
    func testAMBCountingRESTAsActivity(includeHeader: Bool) {
        let sessionManager = SessionManager(configuration: .ephemeral)
        
        let privateRESTAPI = instanceConfiguration.privateRESTAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        let handshakeExpectation = XCTestExpectation(description: "AMB handshake")
        let connectFinishedExpectation = XCTestExpectation(description: "AMB connect")
        
        // Get session cookie via access token headers
        func logIn() {
            var headers = instanceConfiguration.accessTokenAuthHeaders
            // Add this header for this rest call to count as user activity for AMB
            if includeHeader {
                headers["X-User-Activity"] = "true"
            }
            
            sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    ensureSession()
            }
            .resume()
        }
        
        // Verify cookie works
        func ensureSession() {
            sessionManager.request(privateRESTAPI, method: .get)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    ensureSessionExpectation.fulfill()
                    print("Finished ensure session.")
                    
                    handshake()
            }
            .resume()
        }
        
        // Setup the AMB dance!
        var ambClientId: String?
        var ambCount = 0
        
        func handshake() {
            let url = instanceConfiguration.urlWithPath("amb/handshake")
            let params: Parameters = ["supportedConnectionTypes": ["long-polling"],
                                      "id": ambCount,
                                      "channel": "/meta/handshake",
                                      "minimumVersion": "1.0beta",
                                      "version": "1.0"]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let array = response.result.value as? [Any] ?? []
                    let dictionary = array.first as? [String : Any] ?? [:]
                    let clientId = dictionary["clientId"] as? String ?? ""
                    let success = dictionary["successful"] as? Bool ?? false
                    
                    XCTAssertTrue(success)
                    XCTAssertFalse(clientId.isEmpty)
                    
                    ambClientId = clientId
                    
                    handshakeExpectation.fulfill()
                    print("Finished handshake.")
                    connect()
            }
            .resume()
        }
        
        func connect() {
            ambCount += 1
            
            let url = instanceConfiguration.urlWithPath("amb/connect")
            let params: Parameters = ["id": ambCount,
                                      // swiftlint:disable:next force_unwrapping
                                      "clientId": ambClientId!,
                                      "channel": "/meta/connect",
                                      "connectionType": "long-polling"]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    print("Finished connect.")
                    
                    let messages = response.result.value as? [[String : Any]] ?? []
                    messages.forEach({ (message) in
                        let ext = message["ext"] as? [String : Any]
                        let sessionStatus = ext?["glide.session.status"]
                        if includeHeader {
                            let stringSessionStatus = sessionStatus as? String ?? ""
                            XCTAssert(stringSessionStatus == "session.logged.in")
                        } else {
                            XCTAssert(sessionStatus is NSNull)
                        }
                    })
                    connectFinishedExpectation.fulfill()
            }
            .resume()
        }
        
        logIn()
        
        self.wait(for: [connectFinishedExpectation], timeout: 30)
        self.wait(for: [handshakeExpectation], timeout: 20)
        self.wait(for: [ensureSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 5)
    }
    
    /// This demonstrates that record watcher will send a record deleted notifications over AMB
    /// even after the subscribed user has been logged out (according to glide session status).
    /// This is not expected behavior and this test will be marked as a failure if it gets the delete message.
    /// The general flow of this test is log in -> handshake -> subscribe -> connect -> wait for logout -> get notified of delete from ITIL user
    // swiftlint:disable:next function_body_length
    func testRecordWatcherDeleteWhileLoggedOut() {
        
        let sessionManager = SessionManager(configuration: .ephemeral)
        let itilSessionManager = SessionManager(configuration: .ephemeral)
        
        let privateRESTAPI = instanceConfiguration.privateRESTAPI
        
        let logInExpectation = XCTestExpectation(description: "Log in to instance")
        let ensureSessionExpectation = XCTestExpectation(description: "Ensure session")
        let handshakeExpectation = XCTestExpectation(description: "AMB handshake")
        let connectLoopFinishedExpectation = XCTestExpectation(description: "AMB connect")
        
        let createIncidentExpectation = XCTestExpectation(description: "Create incident as ITIL user")
        let deleteIncidentExpectation = XCTestExpectation(description: "Delete incident as ITIL user")
        
        let tableToWatch = "sysapproval_group"
        var newRecordSysId: String?
        
        // Create a record that we'll end up deleting
        func createNewRecordAsITILUser() {
            let url = instanceConfiguration.apiURLWithPath("table/\(tableToWatch)", version: 2)
            
            itilSessionManager.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.itilBasicAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let dictionary = response.result.value as? [String: Any] ?? [:]
                    let result = dictionary["result"] as? [String: Any] ?? [:]
                    let sysId = result["sys_id"] as? String ?? ""
                    
                    XCTAssertFalse(sysId.isEmpty)
                    
                    newRecordSysId = sysId
                    
                    createIncidentExpectation.fulfill()
                    print("Created new incident.")
                    
                    logIn()
            }
        }
        
        // Get session cookie via access token headers
        func logIn() {
            sessionManager.request(privateRESTAPI, method: .get, parameters: nil, encoding: URLEncoding.default, headers: instanceConfiguration.accessTokenAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    logInExpectation.fulfill()
                    print("Finished log in.")
                    
                    ensureSession()
            }
            .resume()
        }
        
        // Verify cookie works
        func ensureSession() {
            sessionManager.request(privateRESTAPI, method: .get)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    ensureSessionExpectation.fulfill()
                    print("Finished ensure session.")
                    
                    handshake()
            }
            .resume()
        }
        
        // Setup the AMB dance!
        let ambChannel = "/rw/default/\(tableToWatch)/T1JERVJCWW51bWJlcg--"
        var ambClientId: String?
        var ambCount = 0
        var sessionStatusHasEverBeenLoggedOut = false
        var maxNumberOfAMBCalls = 8
        
        func handshake() {
            let url = instanceConfiguration.urlWithPath("amb/handshake")
            let params: Parameters = ["supportedConnectionTypes": ["long-polling"],
                                      "id": ambCount,
                                      "channel": "/meta/handshake",
                                      "minimumVersion": "1.0beta",
                                      "version": "1.0"]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let array = response.result.value as? [Any] ?? []
                    let dictionary = array.first as? [String : Any] ?? [:]
                    let clientId = dictionary["clientId"] as? String ?? ""
                    let success = dictionary["successful"] as? Bool ?? false
                    
                    XCTAssertTrue(success)
                    XCTAssertFalse(clientId.isEmpty)
                    
                    ambClientId = clientId
                    
                    handshakeExpectation.fulfill()
                    print("Finished handshake.")
                    subscribe()
            }
            .resume()
        }
        
        // Subscribe to the AMB channel
        func subscribe() {
            ambCount += 1
            
            let url = instanceConfiguration.urlWithPath("amb")
            let params: Parameters = ["subscription": ambChannel,
                                      "channel": "/meta/subscribe",
                                      "id": ambCount,
                                      // swiftlint:disable:next force_unwrapping
                                      "clientId": ambClientId!]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    
                    let array = response.result.value as? [Any] ?? []
                    let dictionary = array.first as? [String : Any] ?? [:]
                    let success = dictionary["successful"] as? Bool ?? false
                    
                    XCTAssertTrue(success)
                    
                    print("Finished subscribe.")
                    connect()
            }
            .resume()
        }
        
        func connect() {
            ambCount += 1
            
            let url = instanceConfiguration.urlWithPath("amb/connect")
            let params: Parameters = ["id": ambCount,
                                      // swiftlint:disable:next force_unwrapping
                                      "clientId": ambClientId!,
                                      "channel": "/meta/connect",
                                      "connectionType": "long-polling"]
            
            sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    print("Finished connect.")
                    
                    let messages = response.result.value as? [[String : Any]] ?? []
                    let sessionStatues: [String] = messages.flatMap({ (message) in
                        let ext = message["ext"] as? [String : Any]
                        let sessionStatus = ext?["glide.session.status"] as? String
                        return sessionStatus
                    })
                    
                    let recordSysIds: [String] = messages.flatMap({ (message) in
                        let data = message["data"] as? [String : Any]
                        let sysId = data?["sys_id"] as? String
                        return sysId
                    })
                    
                    if let newRecordSysId = newRecordSysId, sessionStatusHasEverBeenLoggedOut && recordSysIds.contains(newRecordSysId) {
                        // We shouldn't be notified of the record changing if we've been logged out.
                        // This is the bug I've seen.
                        XCTFail("Got record watcher message after being logged out. Failing test.")
                        
                        connectLoopFinishedExpectation.fulfill()
                        
                        return
                    }
                    
                    if sessionStatues.contains("session.logged.out") {
                        if !sessionStatusHasEverBeenLoggedOut {
                            // When we get logged out for the first time, have the ITIL user delete a record
                            // Feel free to adjust this delay – it seems to happen regardless.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0, execute: {
                                deleteNewRecordAsITILUser()
                            })
                        }
                        
                        sessionStatusHasEverBeenLoggedOut = true
                    }
                    
                    if ambCount < maxNumberOfAMBCalls {
                        connect()
                    } else {
                        connectLoopFinishedExpectation.fulfill()
                    }
            }
            .resume()
        }
        
        func deleteNewRecordAsITILUser() {
            guard let sysId = newRecordSysId else {
                XCTFail("Expected incident sys id")
                deleteIncidentExpectation.fulfill()
                return
            }
            
            let url = instanceConfiguration.apiURLWithPath("table/\(tableToWatch)/\(sysId)", version: 2)
            
            itilSessionManager.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: instanceConfiguration.itilBasicAuthHeaders)
                .validate()
                .responseJSON { response in
                    XCTAssert(response.result.isSuccess)
                    deleteIncidentExpectation.fulfill()
                    print("Deleted incident.")
            }
        }
        
        createNewRecordAsITILUser()
        
        self.wait(for: [connectLoopFinishedExpectation], timeout: 120)
        self.wait(for: [deleteIncidentExpectation], timeout: 120)
        self.wait(for: [handshakeExpectation], timeout: 20)
        self.wait(for: [ensureSessionExpectation], timeout: 10)
        self.wait(for: [logInExpectation], timeout: 10)
        self.wait(for: [createIncidentExpectation], timeout: 5)
    }
    
}
