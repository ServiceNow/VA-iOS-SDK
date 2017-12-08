//
//  CBStoreTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import XCTest

@testable import SnowChat

class CBStoreTests: XCTestCase {

    var store: ChatDataStore?
    
    override func setUp() {
        super.setUp()
        
        store = ChatDataStore(storeId: "CBStoreTests_Store")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    fileprivate func newControlData() -> RichControlData<ControlWrapper<Bool?, UIMetadata>> {
        return RichControlData<ControlWrapper>(sessionId: "100",
                                               conversationId: nil,
                                               controlData: ControlWrapper(model: ControlModel(type: "Boolean", name: "Boolean"),
                                                                           uiType: "BooleanControl",
                                                                           uiMetadata: UIMetadata(label:"Test",
                                                                                                  required: false,
                                                                                                  error: nil),
                                                                           value: nil))
    }
    
    func testStoreBooleanControl() {
        let booleanData = BooleanControlMessage(withData: newControlData())
        
        let expect = expectation(description: "Expect Notification for Boolean Control")
        let subscriber = subscribeForAddEvent(booleanData, expect)
        
        store?.didReceiveBooleanControl(booleanData, fromChat: Chatterbox())

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
        
        NotificationCenter.default.removeObserver(subscriber)
        
        updateBooleanControl(booleanData: booleanData, expectedId: booleanData.id)
    }
    
    fileprivate func subscribeForAddEvent(_ booleanData: BooleanControlMessage, _ expect: XCTestExpectation) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(ChatDataStore.ChatNotificationType.booleanControl.rawValue), object: nil, queue: nil) { notification in
            
            let info = notification.userInfo as! [String: Any]
            let notificationData = info["state"] as! BooleanControlMessage
            
            XCTAssert(notificationData.controlType == .boolean)
            XCTAssertEqual(notificationData.id, booleanData.id)
            XCTAssertEqual(notificationData.data.richControl?.model?.type, booleanData.data.richControl?.model?.type)
            //XCTAssertEqual(notificationData.data.richControl?.value, nil)
            
            expect.fulfill()
        }
    }
    
    func updateBooleanControl(booleanData: BooleanControlMessage, expectedId: String) {
        let expect = expectation(description: "Expect Notification for Boolean Control update")
        let subscriber = subscribeForUpdateEvent(expectedId, expect)
        
        var updateData = booleanData
        updateData.data.richControl?.value = true
        store?.didReceiveBooleanControl(updateData, fromChat: Chatterbox())
        
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
        NotificationCenter.default.removeObserver(subscriber)
    }
    
    fileprivate func subscribeForUpdateEvent(_ expectedId: String, _ expect: XCTestExpectation) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(ChatDataStore.ChatNotificationType.booleanControl.rawValue), object: nil, queue: nil) { notification in
            
            let info = notification.userInfo as! [String: Any]
            let notificationData = info["state"] as! BooleanControlMessage
            
            XCTAssert(notificationData.controlType == .boolean)
            XCTAssertEqual(notificationData.id, expectedId)
            XCTAssertEqual(notificationData.data.richControl?.value!, true)
            
            expect.fulfill()
        }
    }
    

}
