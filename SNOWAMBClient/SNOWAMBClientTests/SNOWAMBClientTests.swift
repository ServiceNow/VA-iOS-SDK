import XCTest
@testable import SNOWAMBClient

import Foundation

class SNOWAMBClientTests: XCTestCase {
    
    enum ExpectationType: String {
        case handshaken
        case connected
        case disconnected
        case subscribed
        case published
        case unsubscribed
        case messageReceived
        case glideLoggedIn
        case glideLoggedOut
        case errorOccurred
    }
    
    var testExpectations: [ExpectationType : XCTestExpectation] = [ : ]
    
    let loggedInExpectation = XCTestExpectation(description: "Client logged in")
    
    let session = URLSession(configuration: .default)
    let baseURL = URL(string: "https://snowchat.service-now.com")
//    let baseURL = URL(string: "http://localhost:8080")
    let username = "admin"
//    let password = "snow2004"
    let password = "admin"
    let testChannelName = "C3E4C47D16AC4B8ABB424F59B7C29FF3"
    var ambHTTPClient: SNOWTestHTTPClient?
    var ambClient: SNOWAMBClient?
    var accessToken = ""
    
    var privateRESTAPI: URL?
    var publicRESTAPI: URL?
    
    var dataTask: URLSessionDataTask?
    
    enum HTTPHeaderField {
        static let userToken = "X-UserToken"
        static let userTokenRequest = "X-UserToken-Request"
        static let userTokenResponse = "X-UserToken-Response"
        static let authorizeByCookieFirst = "X-AuthorizeByCookieFirst"
        static let isLoggedIn = "X-Is-Logged-In"
        static let authorization = "Authorization"
        static let endUser = "X-End-User"
    }
    
    typealias HTTPHeaders = [String : String]
    var authHeaders: HTTPHeaders = HTTPHeaders()
    
    private func urlWithPath(_ path: String) -> URL {
        return baseURL!.appendingPathComponent(path)
    }
    
    private func apiURLWithPath(_ path: String, version: Int = 1) -> URL {
        return urlWithPath("/api/now/v\(version)").appendingPathComponent(path)
    }
    
    private func accessTokenAuthHeaders() -> HTTPHeaders {
        return ["Authorization" : "Bearer \(accessToken)"]
    }
    
    private func basicAuthHeaders(username: String, password: String) -> HTTPHeaders {
        let credentials = "\(username):\(password)"
        let data = credentials.data(using: .utf8)
        let base64Auth = data?.base64EncodedString() ?? ""
        let authValue = "Basic \(base64Auth)"
        return ["Authorization" : authValue]
    }

    override func setUp() {
        super.setUp()
        
        privateRESTAPI = apiURLWithPath("mobile/app_bootstrap/post_auth")
        publicRESTAPI = apiURLWithPath("mobile/app_bootstrap/pre_auth")
        authHeaders = basicAuthHeaders(username: username, password: password)
        
        ambHTTPClient = SNOWTestHTTPClient(baseURL: baseURL!)
        ambClient = SNOWAMBClient(httpClient: ambHTTPClient!)
        
        login()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func httpRequest(url: URL, headers: HTTPHeaders, completion handler: @escaping (SNOWAMBResult<Data>) -> Void) -> Void {
        
        func addHeaders(toRequest request: inout URLRequest) {
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(toRequest: &request)
        dataTask = session.dataTask(with: request as URLRequest) { data, response, error in
//            defer { self.dataTask = nil }
            if let error = error {
                let errorMessage = "http error: " + error.localizedDescription
                if let response = response as? HTTPURLResponse {
                    handler(SNOWAMBResult.failure(SNOWAMBError.httpRequestFailed(description: "http status code:\(response.statusCode) \(errorMessage)")))
                } else {
                    handler(SNOWAMBResult.failure(SNOWAMBError.httpRequestFailed(description: "error \(errorMessage)")))
                }
            } else if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    handler(SNOWAMBResult.success(data!))
                } else {
                    handler(SNOWAMBResult.failure(SNOWAMBError.httpRequestFailed(description: "http status code:\(response.statusCode)")))
                }
            }
        }
        self.dataTask?.resume()
    }
    
    private func login() {
        httpRequest(url: privateRESTAPI!, headers: authHeaders) { [weak self] result in
            XCTAssert(result.isSuccess, "login failed")
            self?.loggedInExpectation.fulfill()
            print("looged in")
        }
    }
    
    private func waitForLogin() {
        self.wait(for: [loggedInExpectation], timeout: 1000)
    }

    func testHandshake() {
        waitForLogin()
        
        let handshakenExpectation = XCTestExpectation(description: "AMB handshake")
        let glideLoggedInExpectation = XCTestExpectation(description: "AMB Glide session logged in")
        testExpectations.removeAll()
        testExpectations[ExpectationType.handshaken] = handshakenExpectation
        testExpectations[ExpectationType.glideLoggedIn] = glideLoggedInExpectation
        ambClient?.delegate = self
        
        ambClient?.connect()

        self.wait(for: [handshakenExpectation], timeout: 10)
        self.wait(for: [glideLoggedInExpectation], timeout: 10)
        ambClient?.tearDown()
    }
    
    func testPerformanceExample() {
        self.measure {
        }
    }
    
}

//
// SNOWAMBClientDelegate
//

extension SNOWAMBClientTests: SNOWAMBClientDelegate {
    func ambClientDidConnect(_ client: SNOWAMBClient) {
        if let expectation = testExpectations[ExpectationType.handshaken] {
            expectation.fulfill()
        }
        if let expectation = testExpectations[ExpectationType.connected] {
            expectation.fulfill()
        }
    }
    
    func ambClientDidDisconnect(_ client: SNOWAMBClient) {
        if let expectation = testExpectations[ExpectationType.disconnected] {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: SNOWAMBClient, didSubscribeToChannel channel: String) {
        if let expectation = testExpectations[ExpectationType.subscribed],
            channel == testChannelName {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: SNOWAMBClient, didUnsubscribeFromchannel channel: String) {
        if let expectation = testExpectations[ExpectationType.unsubscribed],
            channel == testChannelName {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: SNOWAMBClient, didReceiveMessage: SNOWAMBMessage, fromChannel channel: String) {
        if let expectation = testExpectations[ExpectationType.messageReceived],
            channel == testChannelName {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: SNOWAMBClient, didChangeClientStatus status: SNOWAMBClientStatus) {
        // Anything to do here???
    }
    
    func ambClient(_ client: SNOWAMBClient, didChangeGlideStatus status: SNOWAMBGlideStatus) {
        switch status.sessionStatus! {
        case AMBGlideSessionStatus.loggedIn.rawValue:
            if let expectation = testExpectations[ExpectationType.glideLoggedIn] {
                expectation.fulfill()
            }
        case AMBGlideSessionStatus.loggedOut.rawValue:
            if let expectation = testExpectations[ExpectationType.glideLoggedOut] {
                expectation.fulfill()
            }
        default:
            XCTAssertTrue(false, "unexpected gilde session status")
        }
    }
    
    func ambClient(_ client: SNOWAMBClient, didFailWithError error: SNOWAMBError) {
        if let expectation = testExpectations[ExpectationType.errorOccurred] {
            expectation.fulfill()
        } else {
            // if error was not expected, then test fails
            XCTAssertTrue(false, "unexpected error occurred \(error.localizedDescription)")
        }
    }
}
