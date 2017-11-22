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
    let channel = CBChannel(name: "CBStoreTestChannel")
    
    override func setUp() {
        super.setUp()
        
        store = ChatDataStore(storeId: "Store01")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStoreBooleanControl() {
        let controlData = RichControlData<SystemTextMessage.ControlWrapper>(sessionId: 100, controlData: SystemTextMessage.ControlWrapper(uiMetadata: SystemTextMessage.UIMetadata(label:"Test", required: false), model: SystemTextMessage.ModelType(type: "Boolean")))
        let booleanData = BooleanControlMessage(id: "foo", controlType: .controlBoolean, type: "Boolean", data: controlData)
        let expect = expectation(description: "Expect Notification for Boolean Control")
        
        _ = NotificationCenter.default.addObserver(forName: ChatNotification.name(forKind: .booleanControl),
                                               object: nil, queue: nil) { notification in
            let info = notification.userInfo as! [String: Any]
            let notificationData = info["state"] as! BooleanControlMessage
        
            XCTAssert(notificationData.controlType == .controlBoolean)
            XCTAssertEqual(notificationData.id, booleanData.id)
            XCTAssertEqual(notificationData.data.richControl.model.type, booleanData.data.richControl.model.type)
            
            expect.fulfill()
        }
        
        store?.onBooleanControl(forChannel: channel, withControlData: booleanData)

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
}
