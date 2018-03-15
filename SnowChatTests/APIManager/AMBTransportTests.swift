import XCTest
@testable import SnowChat

class AMBTransportTests: XCTestCase {
    
    let serverInstance = ServerInstance(instanceURL: URL(string: "https://snowchat.service-now.com")!)
    let testChannelName = "C3E4C47D16AC4B8ABB424F59B7C29FF3"
    
    var apiManager: APIManager?
    
    func setup() {
        super.setUp()
        apiManager = APIManager(instance: serverInstance)
        XCTAssert(apiManager != nil, "API Manager is nil")
    }
    
    func testSubscription() {
        let receivedMessageExpectation = XCTestExpectation(description: "Received AMB message")
        let publishedMessageExpectation = XCTestExpectation(description: "Published AMB message")
        
        let subscription = apiManager?.subscribe(testChannelName) { (result, subscription) in
            switch result {
                case .success:
                    let message = result.value
                    XCTAssert(message != nil, "AMB message is nil")
                    receivedMessageExpectation.fulfill()
                    self.apiManager?.sendMessage(["test_field" : "test_value"], toChannel: self.testChannelName, completion: { result in
                        XCTAssert(result.isSuccess)
                        publishedMessageExpectation.fulfill()
                })
                case .failure:
                    XCTFail("AMB message received with error: \(String(describing: result.error?.localizedDescription))")
            }
        }
        XCTAssert(subscription != nil, "AMB subscription is nil")
        self.wait(for: [receivedMessageExpectation], timeout: 10)
        self.wait(for: [publishedMessageExpectation], timeout: 10)
    }
}
