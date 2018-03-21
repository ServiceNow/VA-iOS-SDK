import XCTest
import Alamofire
@testable import SnowChat

class AMBTransportTests: XCTestCase {
    
    let serverInstanceURL = URL(string: "https://snowchat.service-now.com")!
    var serverInstance: ServerInstance?
    let privateRESTAPI = "mobile/app_bootstrap/post_auth"
    let username = "admin"
    let password = "snow2004"
    let testChannelName = "C3E4C47D16AC4B8ABB424F59B7C29FF3"
    
    var basicAuthHeaders: HTTPHeaders {
        return basicAuthHeaders(username: username, password: password)
    }
    
    private func basicAuthHeaders(username: String, password: String) -> HTTPHeaders {
        let credentials = "\(username):\(password)"
        let data = credentials.data(using: .utf8)
        let base64Auth = data?.base64EncodedString() ?? ""
        let authValue = "Basic \(base64Auth)"
        return ["Authorization" : authValue]
    }
    
    private func apiURLWithPath(_ path: String, version: Int = 1) -> URL {
        return urlWithPath("/api/now/v\(version)").appendingPathComponent(path)
    }
    
    private func urlWithPath(_ path: String) -> URL {
        return serverInstanceURL.appendingPathComponent(path)
    }
    
    var apiManager: APIManager?
    let sessionManager = SessionManager(configuration: .ephemeral)
    
    override func setUp() {
        super.setUp()
        serverInstance = ServerInstance(instanceURL: serverInstanceURL)
        apiManager = APIManager(instance: serverInstance!)
        login()
    }
    
    func login() {
        sessionManager.request(apiURLWithPath(privateRESTAPI), method: .get, parameters: nil, encoding: URLEncoding.default, headers: basicAuthHeaders)
            .validate()
            .responseJSON { [weak self] response in
                XCTAssert(response.result.isSuccess)
                print("Finished log in.")
                
                self?.apiManager?.ambClient.connect()
        }
    }
    
    func testSubscription() {
        let connectedExpectation = XCTestExpectation(description: "AMB is connected")
        let subscribedExpectation = XCTestExpectation(description: "Client is subscribed to test channel")
        let receivedMessageExpectation = XCTestExpectation(description: "Received AMB message")
        let publishedMessageExpectation = XCTestExpectation(description: "Published AMB message")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            XCTAssert(self.apiManager?.ambClient.clientStatus == .connected,
                      "AMB status is \(String(describing: self.apiManager?.ambClient.clientStatus)). Must be .connected")
            connectedExpectation.fulfill()
        }
        
        let subscription = apiManager?.subscribe(testChannelName) { (result, subscription) in
            switch result {
            case .success:
                let message = result.value
                XCTAssert(message != nil, "AMB message is nil")
                receivedMessageExpectation.fulfill()
            case .failure:
                XCTFail("AMB message received with error: \(String(describing: result.error?.localizedDescription))")
            }
        }
        XCTAssert(subscription != nil, "AMB subscription is nil")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if subscription!.subscribed {
                subscribedExpectation.fulfill()
            }
        }
        self.wait(for: [subscribedExpectation], timeout: 100)
        
        self.apiManager?.sendMessage(["test_field" : "test_value"], toChannel: self.testChannelName, completion: { result in
            XCTAssert(result.isSuccess)
            publishedMessageExpectation.fulfill()
        })
        
        self.wait(for: [connectedExpectation], timeout: 10)
        
        self.wait(for: [receivedMessageExpectation], timeout: 100)
        self.wait(for: [publishedMessageExpectation], timeout: 100)
    }
}
