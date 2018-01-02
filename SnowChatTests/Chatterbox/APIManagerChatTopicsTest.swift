//
//  APIManagerChatTopicsTest.swift
//  SnowChatTests
//
//  Created by Will Lisac on 12/21/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest

@testable import SnowChat

class APIManagerChatTopicsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTopicsFromResult() throws {
        let jsonString = """
        {
            "root": [
                {
                    "title": "item 1",
                    "topicName": "ITEM1"
                },
                {
                    "title": "item 2",
                    "topicName": "ITEM2"
                },
                {
                    "title": "item 3",
                    "topicName": "ITEM3"
                }
            ]
        }
        """
        do {
            let jsonData = jsonString.data(using: .utf8)
            let result = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments)
            let topics = APIManager.topicsFromResult(result)
            XCTAssertEqual(topics.count, 3)
            XCTAssertEqual(topics[0].name, "ITEM1")
            XCTAssertEqual(topics[1].name, "ITEM2")
            XCTAssertEqual(topics[2].name, "ITEM3")
            XCTAssertEqual(topics[0].title, "item 1")
            XCTAssertEqual(topics[1].title, "item 2")
            XCTAssertEqual(topics[2].title, "item 3")
        } catch let err {
            throw err
        }
    }
    
    func testtopicsFromResultInvalidItem() throws {
        let jsonString = """
        {
            "root": [
                {
                    "title": "item 1",
                    "topicName": "ITEM1"
                },
                {
                    "title": "item 2"
                },
                {
                    "title": "item 3",
                    "topicName": "ITEM3"
                }
            ]
        }
        """
        do {
            let jsonData = jsonString.data(using: .utf8)
            let result = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments)
            let topics = APIManager.topicsFromResult(result)
            XCTAssertEqual(topics.count, 2)
            XCTAssertEqual(topics[0].name, "ITEM1")
            XCTAssertEqual(topics[1].name, "ITEM3")
            XCTAssertEqual(topics[0].title, "item 1")
            XCTAssertEqual(topics[1].title, "item 3")
        } catch let err {
            throw err
        }
    }
}

