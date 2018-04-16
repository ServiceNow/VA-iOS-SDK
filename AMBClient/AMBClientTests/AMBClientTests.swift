import XCTest
@testable import AMBClient

import Foundation

class AMBClientTests: XCTestCase {
    
    enum ExpectationType: String {
        case handshaken
        case connected
        case disconnected
        case subscribed
        case published
        case unsubscribed
        case messagePublished
        case messageReceived
        case glideInitialState
        case glideLoggedIn
        case glideLoggedOut
        case errorOccurred
    }
    
    var testExpectations: [ExpectationType : XCTestExpectation] = [ : ]
    
    var subscription: AMBSubscription?
    
    let loggedInExpectation = XCTestExpectation(description: "Client logged in")
    
    let session = URLSession(configuration: .default)
    let baseURL = URL(string: "https://snowchat.service-now.com")
    let username = "admin"
    let password = "snow2004"
    let testChannelName = "C3E4C47D16AC4B8ABB424F59B7C29FF3"
    var ambHTTPClient: SNOWTestHTTPClient?
    var ambClient: AMBClient?
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
        // swiftlint:disable:next force_unwrapping
        return baseURL!.appendingPathComponent(path)
    }
    
    private func apiURLWithPath(_ path: String, version: Int = 1) -> URL {
        return urlWithPath("/api/now/v\(version)").appendingPathComponent(path)
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
        
        // swiftlint:disable:next force_unwrapping
        ambHTTPClient = SNOWTestHTTPClient(baseURL: baseURL!)
        // swiftlint:disable:next force_unwrapping
        ambClient = AMBClient(httpClient: ambHTTPClient!)
        
        login()
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.subscription = nil
    }
    
    // MARK: - helpers
    
    private func httpRequest(url: URL, headers: HTTPHeaders, completion handler: @escaping (AMBResult<Data>) -> Void) {
        
        func addHeaders(toRequest request: inout URLRequest) {
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(toRequest: &request)
        dataTask = session.dataTask(with: request as URLRequest) { data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                let errorMessage = "http error: " + error.localizedDescription
                if let response = response as? HTTPURLResponse {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: "http status code:\(response.statusCode) \(errorMessage)")))
                } else {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: "error \(errorMessage)")))
                }
            } else if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    // swiftlint:disable:next force_unwrapping
                    handler(AMBResult.success(data!))
                } else {
                    handler(AMBResult.failure(AMBError.httpRequestFailed(description: "http status code:\(response.statusCode)")))
                }
            }
        }
        self.dataTask?.resume()
    }
    
    private func login() {
        // swiftlint:disable:next force_unwrapping
        httpRequest(url: privateRESTAPI!, headers: authHeaders) { [weak self] result in
            XCTAssert(result.isSuccess, "login failed")
            self?.loggedInExpectation.fulfill()
            print("looged in")
        }
    }
    
    private func waitForLogin() {
        self.wait(for: [loggedInExpectation], timeout: 10)
        
    }
    
    func publishMessage() {
        ambClient?.publishMessage(["message": "whatever"], toChannel: testChannelName, withExtension: [:],
                                  completion: { [weak self] (result) in
                                    switch result {
                                    case .success:
                                        if let expectation = self?.testExpectations[ExpectationType.published] {
                                            expectation.fulfill()
                                        }
                                        print("message was published successfully")
                                    case .failure:
                                        XCTFail("AMB failed to publish message")
                                    }
        })
    }

    @discardableResult func subscribeToTestChannel() -> AMBSubscription? {
        subscription = ambClient?.subscribe(channel: testChannelName,
                                            messageHandler: { [weak self] (result, subscription) in
            if result.isSuccess {
                if let message = result.value {
                    if message.messageType == .dataMessage {
                        if let messageReceivedExpectation = self?.testExpectations[ExpectationType.messageReceived] {
                            messageReceivedExpectation.fulfill()
                        }
                    } else {
                        if let subscribedExpectation = self?.testExpectations[ExpectationType.subscribed] {
                            subscribedExpectation.fulfill()
                        }
                    }
                }
            } else {
                XCTFail("AMB message received with error")
            }
        })
        return subscription
    }
    
    // MARK: - Tests

    func testHandshake() {
        waitForLogin()
        
        let handshakenExpectation = XCTestExpectation(description: "AMB handshake")
        let glideInitialStateSetExpectation = XCTestExpectation(description: "AMB Glide session initial state set")

        testExpectations.removeAll()
        testExpectations[ExpectationType.handshaken] = handshakenExpectation
        testExpectations[ExpectationType.glideInitialState] = glideInitialStateSetExpectation
        
        ambClient?.delegate = self
        ambClient?.connect()

        self.wait(for: [handshakenExpectation], timeout: 10)
        self.wait(for: [glideInitialStateSetExpectation], timeout: 10)
        ambClient?.tearDown()
    }
    
    func testSubscribeUnubscribe() {
        waitForLogin()
        
        let handshakenExpectation = XCTestExpectation(description: "AMB handshake")
        let subscribedExpectation = XCTestExpectation(description: "AMB subscribed to test channel")
        let unsubscribedExpectation = XCTestExpectation(description: "AMB unsubscribed from test channel")
        
        testExpectations.removeAll()
        testExpectations[ExpectationType.handshaken] = handshakenExpectation
        testExpectations[ExpectationType.subscribed] = subscribedExpectation
        testExpectations[ExpectationType.unsubscribed] = unsubscribedExpectation
        
        ambClient?.delegate = self
        ambClient?.connect()
        let subscription = subscribeToTestChannel()
        XCTAssert(subscription != nil, "failed to subscribe to test channel")
        
        self.wait(for: [handshakenExpectation], timeout: 10)
        self.wait(for: [subscribedExpectation], timeout: 10)
        XCTAssert(ambClient?.clientId != nil, "clientId is not received")
        subscription?.unsubscribe()
        self.wait(for: [unsubscribedExpectation], timeout: 10)
        
        ambClient?.tearDown()
    }
    
    func testGlideStateLoggedIn() {
        waitForLogin()
        
        let glideLoggedInExpectation = XCTestExpectation(description: "AMB Glide session is \"logged in\"")
        
        testExpectations.removeAll()
        testExpectations[ExpectationType.glideLoggedIn] = glideLoggedInExpectation

        ambClient?.delegate = self
        ambClient?.connect()
        
        // TODO: figure out why glide session status is not set in the beginning as promised (alex a, 04-10-18)
        self.wait(for: [glideLoggedInExpectation], timeout: 10)
    }
    
    func testPublishMessage() {
        waitForLogin()
        
        let publishedMessageExpectation = XCTestExpectation(description: "AMB published message")
        let subscribedExpectation = XCTestExpectation(description: "AMB subscribed to test channel")
        
        testExpectations.removeAll()
        testExpectations[ExpectationType.subscribed] = subscribedExpectation
        testExpectations[ExpectationType.published] = publishedMessageExpectation
        
        ambClient?.delegate = self
        ambClient?.connect()
        subscribeToTestChannel()
        
        self.wait(for: [subscribedExpectation], timeout: 10)
        //publishMessage()
        //!!!
        print("************* publish()")
        self.wait(for: [publishedMessageExpectation], timeout: 100)
    }
    
}

// MARK: - SNOWAMBClientDelegate

extension AMBClientTests: AMBClientDelegate {
    func ambClientDidConnect(_ client: AMBClient) {
        if let expectation = testExpectations[ExpectationType.handshaken] {
            expectation.fulfill()
        }
        if let expectation = testExpectations[ExpectationType.connected] {
            expectation.fulfill()
        }
    }
    
    func ambClientDidDisconnect(_ client: AMBClient) {
        if let expectation = testExpectations[ExpectationType.disconnected] {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: AMBClient, didSubscribeToChannel channel: String) {
        if let expectation = testExpectations[ExpectationType.subscribed],
            channel == testChannelName {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: AMBClient, didUnsubscribeFromChannel channel: String) {
        if let expectation = testExpectations[ExpectationType.unsubscribed],
            channel == testChannelName {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: AMBClient, didReceiveMessage: AMBMessage, fromChannel channel: String) {
        if let expectation = testExpectations[ExpectationType.messageReceived],
            channel == testChannelName {
            expectation.fulfill()
        }
    }
    
    func ambClient(_ client: AMBClient, didChangeClientStatus status: AMBClientStatus) {
        // Anything to do here???
    }
    
    func ambClient(_ client: AMBClient, didReceiveGlideStatus status: AMBGlideStatus) {
        if status.ambActive {
            if let expectation = testExpectations[ExpectationType.glideInitialState] {
                expectation.fulfill()
            }
        }
        
        if let sessionStatus = status.sessionStatus {
            switch sessionStatus {
            case AMBGlideSessionStatus.loggedIn:
                if let expectation = testExpectations[ExpectationType.glideLoggedIn] {
                    expectation.fulfill()
                }
            case AMBGlideSessionStatus.loggedOut:
                if let expectation = testExpectations[ExpectationType.glideLoggedOut] {
                    expectation.fulfill()
                }
            default:
                XCTAssertTrue(false, "unexpected gilde session status")
            }
        }
    }
    
    func ambClient(_ client: AMBClient, didFailWithError error: AMBError) {
        if let expectation = testExpectations[ExpectationType.errorOccurred] {
            expectation.fulfill()
        } else {
            // if error was not expected, then test fails
            print("AMB error: \(error.localizedDescription)")
            XCTFail("unexpected error occurred \(error.localizedDescription)")
        }
    }
}
