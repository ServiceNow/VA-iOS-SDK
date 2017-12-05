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
        let controlData = RichControlData<ControlMessage.ControlWrapper>(sessionId: "100", conversationId: nil, controlData: ControlMessage.ControlWrapper(model: ControlMessage.ModelType(type: "Boolean", name: "Boolean"), uiType: "BooleanControl", value: nil, uiMetadata: ControlMessage.UIMetadata(label:"Test", required: false, error: nil)))
        let booleanData = BooleanControlMessage(id: "foo", controlType: .boolean, type: "Boolean", data: controlData)
        let expect = expectation(description: "Expect Notification for Boolean Control")
        
        _ = NotificationCenter.default.addObserver(forName: ChatNotification.name(forKind: .booleanControl),
                                               object: nil, queue: nil) { notification in
            let info = notification.userInfo as! [String: Any]
            let notificationData = info["state"] as! BooleanControlMessage
        
            XCTAssert(notificationData.controlType == .boolean)
            XCTAssertEqual(notificationData.id, booleanData.id)
            XCTAssertEqual(notificationData.data.richControl?.model?.type, booleanData.data.richControl?.model?.type)
            
            expect.fulfill()
        }
        
        store?.controlEvent(didReceiveBooleanControl: booleanData)

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
}
