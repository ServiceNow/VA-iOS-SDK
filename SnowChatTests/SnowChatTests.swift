//
//  SnowChatTests.swift
//  SnowChatTests
//
//  Created by Will Lisac on 11/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class SnowChatTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRemoveMe() {
        let exp = expectation(description: "Expect testAsync to call us with a string")
        
        RemoveMe.testAsync { msg in
            XCTAssertNotNil(msg)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1) { error in
            XCTAssert(error == nil)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
